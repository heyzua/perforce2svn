require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'perforce2svn/mapping/parser'
require 'perforce2svn/mapping/analyzer'

module Perforce2Svn
  class Migrator
    include Logging
    
    def initialize(migrator_file, options)
      Logging.configure(options[:debug])
      @migration = handle_mapping_file(migrator_file, options)
      if options[:analysis_only]
        exit 0
      end

      @repository_path = options[:repository_path]
    end

    private
    def handle_mapping_file(migration_file, options)
      handle = File.open(migration_file, 'r')
      parser = Perforce2Svn::Mapping::Parser.new(handle, options[:live_path])
      migration = parser.parse!
      
      if parser.parse_failed?
        log.fatal "Parsing failed"
        exit 1
      end

      analyzer = Perforce2Svn::Mapping::Analyzer.new(log, File.dirname(mapping_file))
      if !analyzer.check(migration.commands) || !analyzer.check(migration.branch_mappings)
        log.fatal "Analasys of migration file failed"
        exit 1
      end

      migration
    ensure
      handle.close
    end
  end
end
