require 'optparse'

module Perforce2Svn
  class CLI
    attr_reader :options, :args

    def initialize(args)
      @args = args
    end

    def execute!
      parse!(@args.dup)
      # TODO
    end

    def parse!(args)
      begin
        parse_options(args)
      rescue SystemExit => e
        raise
      rescue Exception => e
        STDERR.puts "#{File.basename($0)}: Unable to parse the command line flags"
        STDERR.puts "Try '#{File.basename($0)} --help' for more information"
        exit 1
      end

      if args.length != 1 
        STDERR.puts "#{File.basename($0)}: Requires the mapping file as an argument"
        exit 1
      end

      if not File.exists? args[0]
        STDERR.puts "#{File.basename($0)}: The mapping file didn't exist: #{args[0]}"
        exit 1
      end
    end

    def parse_options(args)
      @options ||= {}
      @parsed_options ||= OptionParser.new do |opts|
        opts.banner = "Usage: perforce2svn [OPTIONS] MAPPING_FILE"
        opts.separator <<DESC
Description:
    This is a migration tool for migrating specific branches
    in Perforce into Subversion.  It uses a mapping file to
    define the branch mappings at the directory level.

    Because these migrations can be quite complex, and involve
    more sophisticated translations, this mapping file also 
    allows for much more sophisticated operations on the 
    Subversion repository after the migration, at least 
    somewhat mitigating the difficulties in doing complex
    transformations in a unified way.

Mapping File:
    The mapping file has an explicit syntax.  Each line
    contains a directive and a set of arguments.  Each
    argument is separated by a space, though that space
    can be escaped with a '\\' character.  Lines can
    have comments starting with the '#' character and 
    they continue to the end of the line.  

    Please use the '--mapping-help' command for more 
    information.

Options:
DESC
        opts.on('-r', '--repository REPO_PATH',
                "The path to the repository.  It is required.") do |r|
          options[:repository] = r
        end
        opts.on('-l', '--live-path LIVE_PATH',
                "The path to files you want to add or update") do |l|
          options[:live_path] = l
        end
        opts.on('-c', '--changes START_END',
                "The revision range to import from.",
                "Has the format START-END, where START >= 1",
                "and END can be any number or HEAD") do |c|
          options[:changes] = c
        end
        opts.separator ""
        
        opts.on('-u', '--skip-updates',
                "Skip the 'update' actions in the configuration") do |u|
          options[:skip_updates] = u
        end

        opts.on('-p', '--skip-perforce',
                "Skip the perforce step, and run only the actions") do |p|
          options[:skip_perforce] = p
        end

        opts.on('-a', '--analysis-only',
                "Runs the analysis of the mapping file, and then exits") do |a|
          options[:analyze] = a
        end
        opts.separator ""

        # Tail operations
        opts.on_tail('-d', '--debug', 
                     "Prints extra debug information") do |d|
          options[:debug] = d
        end
        
        opts.on_tail('-v', '--version',
                     "Show the version information") do |v|
          puts "perforce2svn version: #{Perforce2Svn::Version.to_s}"
          exit
        end

        opts.on_tail('-m', '--mapping-help',
                     "Shows a detailed mapping file as an example") do |m|
          map_file = File.join(File.dirname(__FILE__), 'mapping_example.txt')
          File.open(map_file, 'r').each do |line|
            puts line
          end
          exit
        end

        opts.on_tail('-h', '--help',
                     "Show this help message") do
          puts opts
          exit
        end
      end.parse!(args)

    end
  end # CLI
end
