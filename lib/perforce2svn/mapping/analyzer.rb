require 'perforce2svn/logging'

module Perforce2Svn::Mapping
  class Analyzer
    
    def initialize(log, base_path)
      @base_path = base_path
      @log = log
    end

    def check(commands)
      # TODO: May want to make this more robust, like checking perforce paths and overlaps
      succeeded = true
      commands.each do |command|
        if command.respond_to? :live_path
          path = command.live_path
          if path !~ /^\//
            path = File.join(@base_path, path)
          end
          
          if not File.exists? path
            @log.error("(line #{command.line_number}) The live path doesn't exist: #{command.live_path}")
            succeeded = false
          end
        end
      end
      succeeded
    end
  end
end
