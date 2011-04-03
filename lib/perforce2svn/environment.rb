require 'choosy/terminal'
require 'perforce2svn/perforce/p4_depot'

module Perforce2Svn
  class Environment
    include Choosy::Terminal

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
        die "Unable to locate svnadmin"
      end
    end

    def check_svnlib
      begin
        require 'svn/core'
      rescue LoadError
        die "Unable to locate the native subversion bindings. Please install."
      end
    end

    def check_perforce
      user = check_env('P4USER')
      server = check_env('P4PORT')

      if !system('p4 help > /dev/null 2>&1')
        die "Unable to locate or execute the 'p4' command. Is it on the PATH? Are you logged in?"
      end
    end

    def check_env(name)
      value = ENV[name]
      if value.nil? || value.empty?
        die "Unable to locate the '#{name}' environment variable"
      end
      value
    end

    def check_p4lib
      begin
        require 'P4'
        if P4.identify =~ /\((\d+.\d+) API\)/
          maj, min = $1.split(/\./)
          if maj.to_i < 2009
            die "Requires a P4 library version >= 2009.2"
          end
        end
      rescue LoadError
        die 'Unable to locate the P4 library, please install p4ruby'
      end
    end

    def check_p4_liveness
      Perforce::P4Depot.instance.connect!
    end
  end
end
