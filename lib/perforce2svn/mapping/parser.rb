require 'perforce2svn/mapping/lexer'

module Perforce2Svn
  module Mapping

    class MappingConfiguration
      attr_accessor :branch_mappings, :commit_range, :repository_path, :svn_prefix, :live_path
    end

    class Parser
      include Perforce2Svn::Logging

      attr_reader :failed

      def initialize(content)
        if not content.respond_to? :readlines
          raise ArgumentError, "The content must respond to 'readlines'"
        end
        @lexer = Lexer.new(content)
      end

      def parse!
        @mapping = MappingConfiguration.new
        @failed = false

        @lexer.each do |tok|
          handle(tok)
        end

        if @failed
          raise MappingParserError, "Unable to parse mapping file"
        end
      end

      private
      def handle(tok)
        case tok[0]
          when 'add'     then insert_command(1, tok)
          when 'copy'    then insert_command(2, tok)
          when 'remove'  then insert_command(1, tok)
          when 'move'    then insert_command(1, tok)
          when 'mkdir'   then insert_command(1, tok)
          when 'update'  then insert_command(1, tok)
          when 'migrate' then insert_migration(tok)
          else handle_property(tok)
        end
      end

      def handle_property(tok)
        case tok[0]
          when 'live-path'       then 
          when 'commit-range'    then
          when 'repository-path' then
          when 'svn-prefix'      then
          when 'live-path'       then
        end
      end
    end
  end
end
