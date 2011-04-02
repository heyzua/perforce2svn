require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'perforce2svn/environment'
require 'perforce2svn/mapping/mapping_file'
require 'perforce2svn/perforce/command_builder'
require 'choosy/terminal'

module Perforce2Svn
  class Migrator
    include Logging
    include Choosy::Terminal
    
    def initialize(migrator_file, options)
      Logging.configure(options[:debug])
      Environment.new.check!

      @migration_file = Mapping::MappingFile.new(migrator_file, options)
      @svnRepo = Perforce2Svn::Subversion::SvnRepo.new(options[:repository_path])
      @command_builder = Perforce::CommandBuilder.new(@migration_file.mappings)
      @version_range = options[:changes]
    end

    def run!
      begin
        @command_builder.commits_in(@version_range) do |commit|
# TODO: 
        end
      rescue SystemExit
        raise
      rescue Interrupt
        @svnRepo.clean_transactions!
        die "Interrupted. Not continuing."
      rescue Exception => e
        log.error e
        die "Unable to complete migration."
      end
    end
  end
end
