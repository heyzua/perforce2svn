require 'perforce2svn/logging'
require 'open3'

module Perforce2Svn
  module Perforce
    
    # Thes standard commit message
    class PerforceCommit
      attr_reader :author, :log, :time, :paths, :revision
      
      def initialize(revision, author, log, time, paths)
        @author = author
        @revision = revision
        @log = log
        @time = time
        @paths = paths
      end

      def to_s
        header = <<EOF
================================================================
Perforce Revision: #{revision}
Time: #{time}
User: #{author}
Total Files: #{paths.length}
Log:
EOF
        log.each do |line|
          header << "   #{line}\n"
        end

        header
      end
    end

    class PerforceFile
      attr_reader :revision, :path, :type, :action

      def initialize(revision, path, type, action)
        @revision = revision
        @path = path
        @type = type
        @action = action
      end

      def binary?
        type =~ /binary/
      end

      def symlink?
        type =~ /symlink/
      end

      def deleted?
        action == 'delete'
      end

      def to_s
        "(#{action}:#{type}@#{revision})\t#{path}"
      end
    end

    # Used to build commit information from the pretty much
    # crazy data the p4 library returns
    class CommitBuilder
      include Perforce2Svn::Logging

      def initialize
        @log_converter = Iconv.new('UTF-8//IGNORE/TRANSLIT', 'UTF-8')
      end

      def build_from(raw_commit)
        revision = raw_commit['change'].to_i
        author = raw_commit['user'].to_i
        commit_log = @log_converter.iconv(raw_commit['desc'].gsub(/\r/, ''))
        time = Time.at(raw_commit['time'].to_i)
        paths = parse_paths(raw_commit)
        
        PerforceCommit.new(revision, author, commit_log, time, paths)
      end

      private
      # The data structures returned from the P4 library
      # are pretty much unusable, so we have to munge them
      # into better objects
      def parse_paths(raw_commit)
        depot_files = raw_commit['depotFile']
        if depot_files.nil? or depot_files.length == 0
          log.dubug "No files relavent"
          return []
        end

        paths = []
        actions = raw_commit['action']
        types = raw_commit['type']
        revisions = raw_commit['rev']

        depot_files.each_index do |i|
          path = depot_files[i]
          action = actions[i]
          type = types[i]
          rev = revisions[i].to_i
          paths << PerforceFile.new(rev, path, type, action)
        end
        paths
      end

    end #PerforceCommit

  end
end
