require 'choosy/terminal'
require 'perforce2svn/perforce/p4_depot'

module Perforce2Svn
  class Environment
    def check!
      check_svnadmin
      check_svnlib
      check_perforce
      check_p4lib
      check_p4_liveness
    end

    private
    def check_svnadmin
      if !command_exists?('svnadmin')
        Terminal.die "Unable to locate svnadmin"
      end
    end

    def check_svnlib
      begin
        require 'svn/core'
      rescue LoadError
        Terminal.die "Unable to locate the native subversion bindings. Please install."
      end
    end

    def check_perforce
      user = check_env('P4USER')
      server = check_env('P4PORT')

      if !system('p4 help > /dev/null 2>&1')
        Terminal.die "Unable to locate or execute the 'p4' command. Is it on the PATH? Are you logged in?"
      end
    end

    def check_env(name)
      value = ENV[name]
      if value.nil? || value.empty?
        Terminal.die "Unable to locate the '#{name}' environment variable"
      end
      value
    end

    def check_p4lib
      begin
        require 'P4'
        if P4.identify =~ /\((\d+.\d+) API\)/
          maj, min = $1.split(/\./)
          if maj.to_i < 2009
            Terminal.die "Requires a P4 library version >= 2009.2"
          end
        end
      rescue LoadError
        Terminal.die 'Unable to locate the P4 library, please install p4ruby'
      end
    end

    def check_p4_liveness
      P4Depot.instance.connect!
    end
  end
end
