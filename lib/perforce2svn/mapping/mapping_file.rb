require 'perforce2svn/logging'
require 'perforce2svn/mapping/parser'
require 'perforce2svn/mapping/analyzer'
require 'choosy/terminal'
require 'choosy/printing/color'

module Perforce2Svn::Mapping
  class MappingFile
    
    def self.help_file
      map_file = File.join(File.dirname(__FILE__), 'help.txt')
      contents = ""
      color = Choosy::Printing::Color.new
      File.open(map_file, 'r') do |file|
        file.each_line do |line|
          contents << if line =~ /^#/
                        color.blue(line)
                      elsif line =~ /^([\w-]+)(.*)/
                        color.green($1) + $2 + "\n"
                      else
                        line
                      end
         end
      end
              
      contents
    end

    attr_reader :mappings, :commands, :author, :message

    def initialize(mapping_file, options)
      load_mapping_file(mapping_file, options)
      analyze(mapping_file)

      if options[:analysis_only]
        exit 0
      end
    end

    private
    def load_mapping_file(migration_file, options)
      migration = nil
      File.open(migration_file, 'r') do |file|
        parser = Parser.new
        migration = parser.parse!(file, options[:live_path])
      end

      if migration[:failed]
        Terminal.die "Parsing the mapping file failed"
      end

      @mappings = migration[:mappings]
      @commands = migration[:commands]
      @author = migration[:author]
      @message = migration[:message]
    end

    def analyze(mapping_file)
      analyzer = Analyzer.new(File.dirname(mapping_file))
      if !analyzer.check(migration.commands) || !analyzer.check(migration.branch_mappings)
        Terminal.die "Analysis of mapping file failed"
      end
    end
  end
end
