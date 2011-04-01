require 'perforce2svn/errors'
require 'perforce2svn/logging'
require 'svn/core'
require 'set'

module Perforce2Svn::Subversion
  class SvnTransaction
    include Perforce2Svn::Logging

    SVN_MIME_TYPE = 'svn:mime-type'
    BINARY_MIME_TYPE = 'application/octet-stream'
    BLOCK_SIZE = 2048

    def initialize(txn)
      @txn = txn
      @possible_deletions = Set.new
    end

    def update(path, content_stream)
      add(path, content_stream)
    end

    def symlink(original_path, new_path)
      mkfile new_path

      # Apply the properties
      @txn.root.set_node_prop(new_path, 'svn:special', '*')
      stream = @txn.root.apply_text(new_path)
      log.debug("SVN: Writing symlink: #{new_path}")
      log.debug("SVN:      Linking to: #{original_path}")
      stream.write("link #{original_path}")
      stream.close
    end

    def add(path, content_stream, binary = false)
      if path.nil? or path == ''
        raise Perforce2Svn::SvnTransactionError, "The subversion path wase empty"
      end

      if not content_stream.respond_to? :readpartial
        raise Perforce2Svn::SvnTransactionError, "The content stream must support block file reading with the 'readpartial' method"
      end

      mkfile path
      # If this is a binary file, set the mime-type
      if binary
        @txn.root.set_node_prop(path, SVN_MIME_TYPE, BINARY_MIME_TYPE)
      end

      # Open the output stream to write the contents to
      outstream = @txn.root.apply_text(path)
      log.debug("SVN: Writing file: #{path}")

      begin
        while buf = content_stream.readpartial(BLOCK_SIZE)
          outstream.write(buf)
        end
      rescue EOFError
        # Always throws an error at the end.  Very weird API.
      end

      outstream.close # close the output stream
      self
    end

    def mkdir(path)
      path_parts = path.split(/\//).delete_if {|p| p == ''}
      current_path = ''
      path_parts.each do |part|
        current_path += '/' + part
        if not exists? current_path
          @txn.root.make_dir(current_path)
          log.debug("SVN: Creating directory: #{current_path}")
        end
      end
    end

    def copy(src_path, dest_path)
      # TODO
    end

    def move(src_path, dest_path)
      # TODO
    end

    def delete(path)
      if exists? path
        @txn.root.delete(path)
        @possible_deletions << parent_path(path)
      end
    end

    def exists?(path)
      @txn.root.check_path(path) != 0
    end

    def has_children?(path)
      @txn.root.dir_entries(path).keys.length != 0
    end

    private
    def parent_path(path)
      File.dirname(path) # seems to work
    end

    # Makes a file if it did not already exist
    def mkfile(path) #:nodoc
      mkdir parent_path(path)
      if not exists? path
        @txn.root.make_file(path)
        log.debug("SVN: Creating file: #{path}")
      end
    end

    # Sent by the SvnRepo at the end of a transaction
    def finalize! #:nodoc
      @possible_deletions.each do |path|
        delete_empty_parents path
      end
    end

    # Deletes all of the empty parents at the end
    # of a transaction
    def delete_empty_parents(path) #:nodoc
      return if path == '/'

      if exists? path and not has_children? path
        @txn.root.delete(path)
        log.debug("SVN: Deleting directory: #{path}")
        delete_empty_parents parent_path(path)
      end
    end
  end #SvnTransaction
end
