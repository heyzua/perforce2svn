require 'perforce2svn/logging'
require 'perforce2svn/mapping/lexer'
require 'perforce2svn/mapping/commands'

module Perforce2Svn::Mapping
  class Parser
    include Perforce2Svn::Logging

    def parse!(content, live_path)
      raise ArgumentError, "The content must respond to 'readlines'" unless content.respond_to? :readlines

      if !live_path.nil? && live_path !~ /\/$/
        live_path << '/'
      end

      ctx = {
        :failed => false, 
        :commands => [], 
        :mappings => [],
        :svn_prefix => '',
        :live_path => live_path
      }

      Lexer.new(content).each do |tok|
        handle(tok, ctx)
      end
      ctx
    end

    private
    def handle(tok, ctx)
      action = tok[0].gsub(/-/, '_')
      if private_methods.include? action
        send(action, tok, ctx)
      else
        log.error "(line: #{tok.line}) Unknown directive: '#{tok[0]}'"
        ctx[:failed] = true
      end
    end

    def add(tok, ctx)
      return if not args_ok?(1, tok, ctx)
      ctx[:commands] << Add.new(tok, to_svn(tok, 1, ctx), to_live(tok, 1, ctx))
    end
      
    def copy(tok, ctx)
      return if not args_ok?(2, tok, ctx)
      ctx[:commands] << Copy.new(tok, to_svn(tok, 1, ctx), to_svn(tok, 2, ctx))
    end

    def remove(tok, ctx)
      return if not args_ok?(1, tok, ctx)
      ctx[:commands] << Remove.new(tok, to_svn(tok, 1, ctx))
    end

    def mkdir(tok, ctx)
      return if not args_ok?(1, tok, ctx)
      ctx[:commands] << Mkdir.new(tok, to_svn(tok, 1, ctx))
    end

    def move(tok, ctx)
      return if not args_ok?(2, tok, ctx)
      ctx[:commands] << Move.new(tok, to_svn(tok, 1, ctx), to_svn(tok, 2, ctx))
    end

    def update(tok, ctx)
      return if not args_ok?(1, tok, ctx)
      ctx[:commands] << Update.new(tok, to_svn(tok, 1, ctx), to_live(tok, 1, ctx))
    end

    def migrate(tok, ctx)
      return if not args_ok?(2, tok, ctx)
      
      p4_path = tok[1]
      p4_path << '/' if not p4_path[-1].chr == '/'
      svn_path = to_svn(tok, 2, ctx)
      svn_path << '/' if not svn_path[-1].chr == '/'

      if p4_path !~ %r|^//([^/]+/?)*$|
        log.error "(line #{tok.line}) Perforce path was malformed: '#{p4_path}'"
        ctx[:failed] = true
      end

      if svn_path !~ %r|^/([^/]+/?)*$|
        log.error "(line #{tok.line}) Subversion path was malformed: '#{svn_path}'"
        ctx[:failed] = true
      end

      ctx[:mappings] << BranchMapping.new(tok, p4_path, svn_path)
    end

    def svn_prefix(tok, ctx)
      return if not args_ok?(1, tok, ctx)
      if not tok[1] =~ /^\//
        log.error "(line: #{tok.line}) 'svn-prefix' directive must start with a '/'"
        ctx[:failed] = true
      else
        ctx[:svn_prefix] = svn_prefix = tok[1]
        if svn_prefix !~ /\/$/
          ctx[:svn_prefix] << '/'
        end
      end
    end

    def args_ok?(required_count, tok, ctx)
      if tok.arg_count != required_count
        log.error "(line: #{tok.line}) '#{tok[0]}' requires #{required_count} argument(s), but found #{tok.arg_count}"
        ctx[:failed] = true
        return false
      end
      return true
    end

    def to_svn(tok, index, ctx)
      if ctx[:svn_prefix].empty? && tok[index] !~ /^\//
        log.error "(line: #{tok.line}) No 'svn-prefix' defined, but a relative SVN path was used"
        ctx[:failed] = true
        nil
      else
        "#{ctx[:svn_prefix]}#{tok[index]}"
      end
    end

    def to_live(tok, index, ctx)
      if ctx[:live_path].nil?
        log.error "(line: #{tok.line}) The command '#{tok[0]}' requires a live path, but none was given."
        ctx[:failed] = true
        nil
      else
        path = tok[index]
        if path =~ /^\//
          "#{ctx[:live_path].chomp('/')}#{path}"
        else
          "#{ctx[:live_path].chomp('/')}#{ctx[:svn_prefix]}#{path}"
        end
      end
    end
  end # Mapping
end
