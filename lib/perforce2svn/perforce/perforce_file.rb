require 'perforce2svn/errors'
require 'perforce2svn/logging'
require 'perforce2svn/perforce/p4_depot'
require 'tmpdir'

module Perforce2Svn::Perforce
  # The collection of properties about a Perforce file
  class PerforceFile
    include Perforce2Svn::Logging

    attr_reader :revision, :src, :dest, :type, :action

    def initialize(revision, src, dest, type, action)
      @revision = revision
      @src = src
      @dest = dest
      @type = type
      @action = action
    end

    # Is this a binary file?
    def binary?
      type =~ /binary/
    end

    # Is this a symlink
    def symlink?
      type =~ /symlink/
    end

    # Was it deleted in the last commit?
    def deleted?
      action == 'delete'
    end

    def to_s
      "(#{@action}:#{@type}\##{@revision})\t#{@src}"
    end

    # Retrieves the target of a symlink
    def symlink_target
      p4query do |p4|
        return p4.run('print', '-q', "#{@src}\##{@revision}")[0].strip
      end
    end

    # Pulls the file contents for a given path for the
    # specific file revision
    def contents
      streamed_contents do |stream|
        return stream.read
      end
    end

    # Pull a stream from a file at a specified file revision
    def streamed_contents(&block)
      raise Perforce2Svn::P4Error, "Requires a block to pull the file stream" unless block_given?
      log.debug {  "PERFORCE: Reading file: #{@src}\##{@revision}" }

      tmpfile = File.join(Dir.tmpdir, ".p4file-#{rand}")
      begin
        P4Depot.instance.query do |p4|
          p4.run('print', '-o', tmpfile, '-q', "#{@src}\##{@revision}")
        end

        if !File.file? tmpfile
          raise Perforce2Svn::P4Error, "Unable to retrieve the file contents: #{src}\##{revision}"
        end

        mode = binary? ? 'rb' : 'r'
        File.open(tmpfile, mode) do |file|
          yield file
        end
      ensure
        if File.file? tmpfile
          File.delete(tmpfile)
        end
      end
    end
  end#PerforceFile
end
