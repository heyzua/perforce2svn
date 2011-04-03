require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'perforce2svn/environment'
require 'perforce2svn/mapping/mapping_file'
require 'perforce2svn/perforce/commit_builder'
require 'perforce2svn/subversion/svn_repo'
require 'perforce2svn/version_range'
require 'choosy/terminal'

module Perforce2Svn
  class Migrator
    include Logging
    include Choosy::Terminal
    
    def initialize(migrator_file, options)
      Logging.configure(options[:debug])
      Environment.new.check!

      @migration_file = Mapping::MappingFile.new(migrator_file, options)
      @svnRepo = Perforce2Svn::Subversion::SvnRepo.new(options[:repository])
      @commit_builder = Perforce::CommitBuilder.new(@migration_file.mappings)
      @version_range = options[:changes] || VersionRange.new(1)
      @options = options
    end

    def run!
      begin
        @commit_builder.commits_in(@version_range) do |commit|
          migrate_commit(commit)
        end unless @options[:skip_perforce]

        execute_commands unless @options[:skip_commands]
      rescue SystemExit
        raise
      rescue Interrupt
        @svnRepo.clean_transactions!
        die "Interrupted. Not continuing."
      rescue Exception => e
        puts e.backtrace
        log.error e
        die "Unable to complete migration."
      end
    end

    private
    def migrate_commit(commit)
      commit.log!
      @svnRepo.transaction(commit.author, commit.time, commit.message) do |txn|
        commit.files.each do |file|
          if file.deleted?
            txn.delete(file.dest)
          elsif file.symlink?
            txn.symlink(file.dest, file.symlink_target)
          else
            file.streamed_contents do |fstream|
              txn.update(file.dest, fstream, file.binary?)
            end
          end
        end
      end
    end

    def execute_commands
      @svnRepo.transaction(@migration_file.author, Time.now, @migration_file.message) do |txn|
        @migration_file.commands.each do |command|
          command.execute!(txn)
        end
      end
    end
  end
end
