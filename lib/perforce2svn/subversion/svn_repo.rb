require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'perforce2svn/subversion/svn_transaction'
require 'svn/repos'
require 'svn/core'
require 'fileutils'
require 'iconv'

module Perforce2Svn::Subversion
  class SvnRepo
    include Perforce2Svn::Logging

    attr_reader :repository_path

    # Initializes a repository at a given path.
    # IF that repository does not exist, it creates one.
    def initialize(repository_path)
      raise ArgumentError, "No path given" if repository_path.nil?

      @repository_path = repository_path

      unless File.directory? repository_path
        fs_config = {
          Svn::Fs::CONFIG_FS_TYPE => Svn::Fs::TYPE_FSFS
        }
        Svn::Repos.create(@repository_path, {}, fs_config)
      end
    end

    def transaction(author, time, log_message, &block)
      if not block_given?
        raise Perforce2Svn::SvnTransactionError, "Transactions must be block-scoped"
      end

      if author.nil? or author == '' or time.nil?
        raise "The author or time was empty"
      end

      props = {
        Svn::Core::PROP_REVISION_AUTHOR => author,
        Svn::Core::PROP_REVISION_DATE => time.to_svn_format,
        Svn::Core::PROP_REVISION_LOG => sanitize(log_message)
      }
    
      begin
        # Yield the transaction
        txn = repository.transaction_for_commit(props)
        svn_txn = SvnTransaction.new(txn, repository.fs.root)
        yield svn_txn
        # Finalize the transaction
        svn_txn.send(:finalize!)

        if not repository.fs.transactions.include?(txn.name)
          log.fatal "Unable to commit the transaction to the repository (#{txn.name}): #{author} #{time}"
          raise Perforce2Svn::SvnTransactionError, "Transaction doesn't exist in repository."
        end
    
        svn_revision = repository.commit(txn)
        # It doesn't look like the 'svn:date' 
        # property gets set correctly during
        # a commit, so we need to update it now
        repository.set_prop(author, # Person authorizing change
                            Svn::Core::PROP_REVISION_DATE, # Property to modify
                            time.to_svn_format, # value
                            svn_revision,   # revision
                            nil,            # callbacks
                            false,          # run pre-commit hooks
                            false)          # run post-commit hooks
        log.info("Committed Subversion revision: #{svn_revision}")
        return svn_revision
      rescue Exception => e
        clean_transactions!
        raise
      end
    end

    # Deletes a repository
    def delete!
      if File.exists? @repository_path
        FileUtils.rm_rf @repository_path
      end
    end

    # Occasionally, we may interrupt a transaction in
    # process.  In that case, we should make sure
    # to clean up after we are done.
    def clean_transactions!
      `svnadmin lstxns #{@repository_path}`.each do |txn|
        `svnadmin rmtxns #{@repository_path} #{txn}`
        if $? != 0
          log.error "Unable to clean transaction: #{txn}"
        end
      end
    end

    # Retrieves the current contents of the file 
    # in the SVN repository at the given path.
    # You can optionally supply the revision number
    #
    # Raises a Svn::Error::FsNotFound if the specific file path cannot
    # be found.
    #
    # Raises a Svn::Error::FsNoSuchRevision if the revision cannot 
    # be found.
    def pull_contents(file_path, revision = nil)
      repository.fs.root(revision).file_contents(file_path){|f| f.read}
    end

    # Checks that a path exists at a revision
    def exists?(path, revision = nil)
      repository.fs.root(revision).check_path(path) != 0
    end

    # Retrieve the commit log for a given revision number
    def commit_log(revision)
      author = repository.prop(Svn::Core::PROP_REVISION_AUTHOR, revision)
      date = repository.prop(Svn::Core::PROP_REVISION_DATE, revision)
      commit_log = repository.prop(Svn::Core::PROP_REVISION_LOG, revision)
      timestamp = Time.parse_svn_format(date)
        
      SvnCommitInfo.new(revision, author, timestamp, commit_log)
    end

    def prop_get(path, prop_name, revision = nil)
      repository.fs.root(revision).node_prop(path, prop_name)
    end

    def children(path, revision = nil)
      repository.fs.root(revision).dir_entries(path).keys
    end

    private
    def repository
      @repository ||= Svn::Repos.open(@repository_path)
    end

    # There can be weird stuff in the log messages, so
    # we make sure that it doesn't bork when committing
    # FIXME: This is replicated in the PerforceCommit, refactor!
    def sanitize(text)
      @sanitizer ||= Iconv.new('UTF-8//IGNORE/TRANSLIT', 'UTF-8')
      @sanitizer.iconv(text.gsub(/\r/, ''))
    end
  end # SvnRepo

  class SvnCommitInfo
    attr_reader :revision, :author, :timestamp, :log
  
    def initialize(revision, author, timestamp, log)
      @revision = revision
      @author = author
      @timestamp = timestamp
      @log = log
    end
  end
end
