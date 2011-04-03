require 'perforce2svn/logging'
require 'perforce2svn/mapping/lexer'
require 'perforce2svn/mapping/commands'
require 'perforce2svn/mapping/branch_mapping'

module Perforce2Svn::Mapping
  class Parser
    include Perforce2Svn::Logging

    def parse!(content, live_path)
      raise ArgumentError, "The content must respond to 'readlines'" unless content.respond_to? :readlines

      live_path = live_path.dup
      if !live_path.nil? && live_path !~ /\/$/
        live_path << '/'
      end

      ctx = {
        :failed => false, 
        :commands => [], 
        :mappings => [],
        :svn_prefix => '',
        :live_path => live_path,
        :author => 'Perforce2Svn Migration Tool',
        :message => 'Perforce Migration'
      }

      Lexer.new(content).each do |tok|
        handle(tok, ctx)
      end
      ctx
    end

    private
    def handle(tok, ctx)
      if private_methods.include? tok.name
        send(tok.name, tok, ctx)
      else
        log.error "(line: #{tok.line_number}) Unknown directive: '#{tok.name}'"
        ctx[:failed] = true
      end
    end

    def author(tok, ctx)
      ctx[:author] = tok.args.join(' ')
    end

    def message(tok, ctx)
      ctx[:message] = tok.args.join(' ')
    end

    def copy(tok, ctx)
      return unless args_ok?(2, tok, ctx)
      ctx[:commands] << Copy.new(tok, format_svn_path(tok, tok[0], ctx), format_svn_path(tok, tok[1], ctx))
    end

    def delete(tok, ctx)
      return unless args_ok?(1, tok, ctx)
      ctx[:commands] << Delete.new(tok, format_svn_path(tok, tok[0], ctx))
    end

    def mkdir(tok, ctx)
      return unless args_ok?(1, tok, ctx)
      ctx[:commands] << Mkdir.new(tok, format_svn_path(tok, tok[0], ctx))
    end

    def move(tok, ctx)
      return unless args_ok?(2, tok, ctx)
      ctx[:commands] << Move.new(tok, format_svn_path(tok, tok[0], ctx), format_svn_path(tok, tok[1], ctx))
    end

    def update(tok, ctx)
      return unless args_ok?(1, tok, ctx)
      ctx[:commands] << Update.new(tok, format_svn_path(tok, tok[0], ctx), format_live_path(tok, tok[0], ctx))
    end

    def migrate(tok, ctx)
      return unless args_ok?(2, tok, ctx)
      
      p4_path = tok[0]
      p4_path << '/' if not p4_path[-1].chr == '/'
      svn_path = format_svn_path(tok, tok[1], ctx)
      svn_path << '/' if not svn_path[-1].chr == '/'

      if p4_path !~ %r|^//([^/]+/?)*$|
        log.error "(line #{tok.line_number}) Perforce path was malformed: '#{p4_path}'"
        ctx[:failed] = true
      end

      if svn_path !~ %r|^/([^/]+/?)*$|
        log.error "(line #{tok.line_number}) Subversion path was malformed: '#{svn_path}'"
        ctx[:failed] = true
      end

      ctx[:mappings] << BranchMapping.new(tok, p4_path, svn_path)
    end

    def svn_prefix(tok, ctx)
      return unless args_ok?(1, tok, ctx)

      svn_prefix = tok[0]
      if svn_prefix !~ /^\//
        log.error "(line: #{tok.line_number}) 'svn-prefix' directive must start with a '/'"
        ctx[:failed] = true
      elsif svn_prefix !~ /\/$/
        svn_prefix << '/'
      end

      ctx[:svn_prefix] = svn_prefix
    end

    def args_ok?(required_count, tok, ctx)
      if tok.args.size != required_count
        log.error "(line: #{tok.line_number}) '#{tok.name}' requires #{required_count} argument(s), but found #{tok.args.size}"
        ctx[:failed] = true
        return false
      end
      return true
    end

    def format_svn_path(tok, path, ctx)
      if ctx[:svn_prefix].empty? && path !~ /^\//
        log.error "(line: #{tok.line_number}) No 'svn-prefix' defined, but a relative SVN path was used"
        ctx[:failed] = true
        nil
      else
        "#{ctx[:svn_prefix]}#{path}"
      end
    end

    def format_live_path(tok, path, ctx)
      if ctx[:live_path].nil?
        log.error "(line: #{tok.line_number}) The command '#{tok.name}' requires a live path, but none was given."
        ctx[:failed] = true
        nil
      else
        if path =~ /^\//
          "#{ctx[:live_path].chomp('/')}#{path}"
        else
          "#{ctx[:live_path].chomp('/')}#{ctx[:svn_prefix]}#{path}"
        end
      end
    end
  end#Parser
end
