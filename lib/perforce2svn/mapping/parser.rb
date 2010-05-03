require 'perforce2svn/mapping/lexer'
require 'perforce2svn/logging'

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
        parse_content
        if @failed
          raise MappingParserError, "Unable to parse mapping file"
        end
      end

      def parse_content
        @mapping = MappingConfiguration.new
        @failed = false
        @lexer.each do |tok|
          handle(tok)
        end
      end

      private
      def handle(tok)
        case tok[0]
          when 'add' then 
            if check_args(1, tok)
              fix_svn_path(1, tok)
            end
          when 'copy' then
            if check_args(2, tok)
              fix_svn_path(1, tok)
              fix_svn_path(2, tok)
            end
          when 'remove' then 
            if check_args(1, tok)
              fix_svn_path(1, tok)
            end
          when 'move' then 
            if check_args(2, tok)
              fix_svn_path(1, tok)
              fix_svn_path(2, tok)
            end
          when 'mkdir' then 
            if check_args(1, tok)
              fix_svn_path(1, tok)
            end
          when 'update' then
            if check_args(1, tok)
              fix_svn_path(1, tok)
            end
          when 'migrate' then
            
            fix_svn_path(2)
         
          when 'svn-prefix' then 
            if not tok[1] =~ /^\//
              log.error "(line: #{tok.line} The 'svn-prefix' directive argument must begin with a '/'"
              @failed = true
            else
              @svn_prefix = tok[1]
            end
          else
            log.error "(line: #{tok.line}): Unknown directive: '#{tok[0]}'"
            @failed = true
        end
      end

      def check_args(required_arguments, tok)
        if tok.value.length != required_arguments + 1
          log.error "(line: #{tok.line}): '#{tok[0]}' requires #{required_arguments} arguments, but found #{tok.values.length - 1}"
          @failed = true
          return false
        end

        return true
      end

      def fix_svn_path(tok_index, tok)
        tok.svn_prefix = @svn_prefix
        if @svn_prefix.nil? and not tok[tok_index] =~ /^\//
          log.error "(line: #{tok.line}) No 'svn-prefix' defined, but a relative SVN path was used"
          @failed = true
        end
      end

      def check_perforce_path(tok)
        puts "TODO"
      end
    end
  end
end
