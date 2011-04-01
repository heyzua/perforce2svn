require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'perforce2svn/mapping/parser'
require 'perforce2svn/mapping/analyzer'
require 'choosy/terminal'

module Perforce2Svn
  class Migrator
    include Logging
    include Choosy::Terminal
    
    def initialize(migrator_file, options)
      Logging.configure(options[:debug])

      @migration = handle_mapping_file(migrator_file, options)
      if options[:analysis_only]
        exit 0
      end

      check_prerequisites

      @svnRepo = Perforce2Svn::Subversion::SvnRepo.new(options[:repository_path])
      @p4depot
    end

    def run!
      begin
        @p4depot.commits do |perforce_commit|
          if perforce_commit.nil?
            log.debug "Skipping empty revision"
          else
            # TODO: 
          end
        end
      rescue SystemExit
        raise
      rescue Interrupt
        @repo.clean_transactions!
        exit 0
      rescue Exception => e
        log.error e
        die "Unable to complete migration."
      end
    end

    private
    def handle_mapping_file(migration_file, options)
      handle = File.open(migration_file, 'r')
      parser = Perforce2Svn::Mapping::Parser.new(handle, options[:live_path])
      migration = parser.parse!
      
      if parser.parse_failed?
        die "Parsing failed"
      end

      analyzer = Perforce2Svn::Mapping::Analyzer.new(log, File.dirname(mapping_file))
      if !analyzer.check(migration.commands) || !analyzer.check(migration.branch_mappings)
        die "Analasys of migration file failed"
      end

      migration
    ensure
      handle.close
    end

    def check_prerequisites
      check_svnadmin
      check_svnlib
      check_perforce
      check_p4lib
    end

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
  end # CLI
end
