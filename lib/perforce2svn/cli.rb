require 'perforce2svn/errors'
require 'choosy'

module Perforce2Svn
  class CLI
    include Choosy::Terminal

    def execute!(args)
      command.execute!(args)
    end

    def parse!(args, propagate=false)
      command.parse!(args, propagate)
    end

    def command
      ctx = self
      Choosy::Command.new :perforce2svn do
        printer :standard
        executor do |args, option|
          ctx.check_perforce_availability
          
          migrator = Migrator.new(args[0], options)
          migrator.run!
        end

        section 'Description:' do
          para 'This is a migration tool for migrating specific branches in Perforce into Subversion.  It uses a mapping file to define the branch mappings at the directory level.'
          para 'Because these migrations can be quite complex, and involve more sophisticated translations, this mapping file also allows for much more sophisticated operations on the Subversion repository after the migration, at least somewhat mitigating the difficulties in doing complex transformations in a unified way.'
        end

        section 'Mapping File:' do
          para "The mapping file has an explicit syntax.  Each line contains a directive and a set of arguments.  Each argument is separated by a space, though that space can be escaped with a '\\' character.  Lines can have comments starting with the '#' character and they continue to the end of the line."
          para "Please use the '--mapping-help' command for more information."
        end

        section 'Options:' do
          string :repository, "The path to the SVN repository. Required." do
            required
            depends_on :mapping_file
          end
          string :live_path, "The path to the files you want to add or update" do
            validate do |args, options|
              if !File.directory?(options[:live_path])
                die "The --live-path must be a directory: #{options[:live_path]}"
              end
            end
          end
          string :changes, "The revision range to import from. This has the format START:END where START >= 1 and END can be any number or 'HEAD'" do
            validate do |args, options|
              if options[:changes] =~ /(\d+):(\d+|HEAD)/
                start = $1.to_i
                if start < 1
                  die "--changes must begin with a revision number >= 1"
                end

                options[:change_start] = start
                options[:change_end] = if $2 != 'HEAD'
                                         last = $2.to_i
                                         if last < 1
                                           die "--changes must end with a revision number >= 1"
                                         end
                                         last
                                        else
                                          -1 # HEAD
                                        end
              else
                die "The --changes must specify a revision range in the format START:END"
              end
            end
          end
          boolean :skip_updates, "Skip the 'update' actions in the configuration", :short => '-u'
          boolean :skip_perforce, "Skip the perforce step, and run only the actions", :short => '-p'
          boolean :analyze_only, "Only analyzes your mapping files for possible errors, but does not attempt to run the migration."
        end

        section 'Informative:' do
          boolean :debug, "Prints extra debug information"
          version Choosy::Version.load_from_parent.to_s
          boolean :mapping_file, "Shows a detailed mapping file example" do
            validate do |args, options|
              map_file = File.join(File.dirname(__FILE__), 'mapping_example.txt')
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
              
              ctx.page(contents)
              exit
            end
          end
          help
        end

        arguments do
          count 1
          metaname 'MAPPING_FILE'

          validate do |args, options|
            if !File.file?(args[0])
              die "the mapping file doesn't exist: #{args[0]}"
            end
          end
        end
      end
    end

    def check_subversion_availability
      begin
        require 'svn/core'
      rescue LoadError
        die "Unable to locate the native subversion bindings. Please install."
      end
    end

    def check_perforce_availability
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
