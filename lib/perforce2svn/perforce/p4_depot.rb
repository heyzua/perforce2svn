require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'tempfile'
require 'P4'

module Perforce2Svn
  module Perforce

    class P4Depot
      include Perforce2Svn::Logging

      # Retrieves the latest revision on the Perforce server
      def latest_revision
        if @latest_revision.nil?
          p4query do |p4|
            log.debug "Retrieving latest perforce revision"
            output = p4.run("changes", "-m1")[0]
            @latest_revision = output['change'].to_i
          end
        end
      end

      # Retrives the PerforceCommit relavent to the given
      # Perforce revision
      def commit_info(revision=nil)
        revision ||= latest_revision
        p4query do |p4|
          log.debug "PERFORCE: Inspecting revision: #{revision}"
          raw_commit = p4.run('describe', '-s', "#{revision}")[0]
          commit = @commit_builder.build_from(perforce_commit)
          return commit
        end
      end

      # Retrieves the target of a symlink
      def symlink_target(path, revision)
        p4query do |p4|
          return p4.run('print', '-q', "#{path}\##{revision}")[0].strip!
        end
      end

      # Pulls the file contents for a given path for the
      # specific file revision
      def pull_contents(path, revision, binary = false)
        pull_stream(path, revision, binary) do |stream|
          return stream.read
        end
      end

      # Pull a stream from a file at a specified file revision
      def pull_stream(path, revision, binary = false)
        if not block_given?
          raise Perforce2Svn::P4Error, "Requires a block to pull the file stream"
        end

        if log.debug?
          log.debug "PERFORCE: Reading file: #{path}@#{revision}"
        end

        tmp = Tempfile.new
        begin
          p4query do |p4|
            p4.run('print', '-o', tmp.path, '-q', "#{path}@#{revision}")
          end

          if not File.exists? tmp.path
            raise Perforce2Svn::P4Error, "Unable to retrieve the file contents: #{path}@#{revision}"
          end

          mode = binary ? 'rb' : 'r'
          yield open(tmp.path, mode)
        ensure
          tmp.close!
        end
      end

      private
      # Creates a new connection to the perforce server
      def p4query(&block)
        p4 = P4.new()

        begin 
          p4.connect()
          yield p4
        rescue P4Exception => e
          p4.warnings.each do |warning|
            log.debug "PERFORCE: Skipping warning: #{warning}"
          end
          if p4.errors.length > 0
            log.error e
            p4.errors.each do |error|
              log.error "PERFORCE: #{error}"
            end
            log.fatal "PERFORCE: Are you currently logged into the Perforce server? "
            raise Perforce2Svn::P4Error, "Error while interacting with the Perforce server"
          end
        ensure
          if p4.connected?
            p4.disconnect
          end
        end
      end

    end # P4Depot

  end
end
