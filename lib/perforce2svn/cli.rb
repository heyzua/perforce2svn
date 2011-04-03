require 'perforce2svn/errors'
require 'perforce2svn/version_range'
require 'perforce2svn/mapping/mapping_file'
require 'perforce2svn/migrator'
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
      version_info = Choosy::Version.load_from_parent
      Choosy::Command.new :perforce2svn do
        printer :manpage, 
                :version => version_info.to_s,
                :date => version_info.date,
                :manual => 'Perforce2Svn'

        executor do |args, options|
          migrator = Migrator.new(args[0], options)
          migrator.run!
        end

        summary 'Migrates Perforce repository files into Subversion'

        section 'DESCRIPTION' do
          para 'This is a migration tool for migrating specific branches in Perforce into Subversion.  It uses a mapping file to define the branch mappings at the directory level.'
          para 'Because these migrations can be quite complex, and involve more sophisticated translations, this mapping file also allows for much more sophisticated operations on the Subversion repository after the migration, at least somewhat mitigating the difficulties in doing complex transformations in a unified way.'
          para 'This utility assumes that you have already logged into Perforce and that the P4USER and P4PORT environment variables are set correctly.'
        end

        section 'OPTIONS' do
          string :repository, "The path to the SVN repository. Required." do
            required
            depends_on :mapping_file # So that the mapping file will get printed and exit before this option gets validated
          end
          string :live_path, "The path to the files you want to add or update." do
            validate do |args, options|
              if !File.directory?(options[:live_path])
                die "The --live-path must be a directory: #{options[:live_path]}"
              end
            end
          end
          string :changes, "The revision range to import from. This has the format START:END where START >= 1 and END can be any number or 'HEAD'." do
            validate do |args, options|
              options[:changes] = VersionRange.build(options[:changes])
            end
          end
          boolean :skip_commands, "Skip the embedded commands in the configuration that are run after the perforce migration.", :short => '-u'
          boolean :skip_perforce, "Skip the perforce migration, and run only the embedded commands.", :short => '-p'
          boolean :analyze_only, "Only analyzes your mapping files for possible errors, but does not attempt to run the migration."

          # Informative
          para 
          boolean :debug, "Prints extra debug information"
          version version_info.to_s
          boolean :mapping_file, "Shows a detailed mapping file example" do
            validate do |args, options|
              ctx.page(Mapping::MappingFile.help_file)
              exit 0
            end
          end
          help
        end

        section 'FILES' do
          para "Rather than define all of the file path mappings between the old Perforce repository and the new Subversion repository, this tool requires you to define a mapping file."
          para "This file contains all of the relevant commands for migrating a complicated set of paths and branches from Perforce into Subversion."
          para "The mapping file has an explicit syntax.  Each line contains a directive and a set of arguments.  Each argument is separated by a space, though that space can be escaped with a '\\' character.  Lines can have comments starting with the '#' character and they continue to the end of the line."
          para "Please use the '--mapping-help' command for more detailed information."
        end

        section 'ENVIRONMENT' do
          para "P4USER   - The username used to connect to the Perforce server."
          para "P4PORT   - The Perforce server name."
          para "svnadmin - This tool must be installed."
          para "p4       - The Perforce command line utility must be installed."
        end

        section 'BUGS AND LIMITATIONS' do
          para "While this tool works better than the other, Perl-based tool, it has the same kind of limitations. Namely, it cannot track certain file changes well (like copying or moving). That requires information that isn't readily accessible."
          para "Also, you may notice that some files are not exactly the same after the migration. The p4 utility occasionally adds newline characters at the end of the file stream, for inexplicable reasons, so sometimes there is an extra newline at the end of some text files. There's really no way around it."
        end

        section "AUTHOR" do
          para "Gabe McArthur <madeonamac@gmail.com>"
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
  end
end
