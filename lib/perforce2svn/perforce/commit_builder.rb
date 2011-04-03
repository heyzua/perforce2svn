require 'perforce2svn/logging'
require 'perforce2svn/perforce/perforce_file'
require 'perforce2svn/perforce/p4_depot'
require 'iconv'
require 'svn/core'

module Perforce2Svn::Perforce
  # The standard commit message
  class PerforceCommit
    include Perforce2Svn::Logging

    attr_reader :author, :log, :time, :revision, :files
    
    def initialize(revision, author, log, time, files)
      @author = author
      @revision = revision
      @log = log
      @time = time
      @files = files
    end

    def log!
      to_s.each_line do |line|
        log.info line
      end
    end

    def to_s
      header = <<EOF
================================================================
Perforce Revision: #{revision}
Time: #{time}
User: #{author}
Log:
EOF
      @log.each_line do |line|
        header << "    #{line}"
      end

      header << "\nTotal Files: #{@files.length}\n"
      @files.each do |file|
        @header << "    #{file}\n"
      end

      header
    end
  end

  # Used to build commit information from the pretty much
  # crazy data the P4 library returns
  class CommitBuilder
    include Perforce2Svn::Logging

    def initialize(mappings)
      @mappings = mappings
      @log_converter = Iconv.new('UTF-8//IGNORE/TRANSLIT', 'UTF-8')
    end

    def commits_in(version_range, &block)
      raise ArgumentError, "Requires a block" unless block_given?
      if version_range.synced_to_head?
        version_range.reset_to_head(P4Depot.instance.latest_revision)
      end

      version_range.min.upto(version_range.max) do |revision|
        commit = commit_at(revision)
        if commit
          yield commit
        else
          log.debug "Skipping irrelevant revision: #{revision}"
        end
      end
    end

    def commit_at(revision)
      P4Depot.instance.query do |p4|
        log.debug "PERFORCE: Inspecting revision: #{revision}"
        raw_commit = p4.run('describe', '-s', "#{revision}")[0]
        return build_from(perforce_commit)
      end
    end

    # Builds from a raw P4 library return
    def build_from(raw_commit)
      changes = unpack_file_changes(raw_commit)
      return nil unless changes

      revision = raw_commit['change'].to_i
      author = raw_commit['user']
      commit_log = @log_converter.iconv(raw_commit['desc'].gsub(/\r/, ''))
      time = Time.at(raw_commit['time'].to_i)
      
      PerforceCommit.new(revision, author, commit_log, time, changes)
    end

    private
    # The data structures returned from the P4 library
    # are pretty much unusable, so we have to munge them
    # into better objects
    def unpack_file_changes(raw_commit)
      depot_files = raw_commit['depotFile']
      if depot_files.nil? || depot_files.length == 0
        log.dubug "No files relavent"
        return nil
      end

      file_changes = []
      actions = raw_commit['action']
      types = raw_commit['type']
      revisions = raw_commit['rev']

      filter_changes(depot_files) do |i, src, dest|
        action = actions[i]
        type = types[i]
        rev = revisions[i].to_i
        file_changes << PerforceFile.new(rev, src, dest, type, action)
      end

      if file_changes.empty?
        log.debug("No relevant files")
        nil
      else
        file_changes
      end
    end

    def filter_changes(depot_files, &block)
      depot_files.each_index do |i|
        src = depot_files[i]
        dest = find_svn_path(src)
        yield i, src, dest if dest
      end
    end

    def find_svn_path(perforce_path)
      @mappings.each do |mapping|
        if mapping.matches_perforce_path? perforce_path
          return mapping.to_svn_path perforce_path
        end
      end
      nil
    end
  end#CommitBuilder
end
