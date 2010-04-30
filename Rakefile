require 'fileutils'
require 'rake'
require 'rubygems'
require 'spec/rake/spectask'

task :default => :spec
task :integration => :spec

desc "Run the RSpec tests for the main perforce2svn tree"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << File.expand_path("../lib", __FILE__)
  t.libs << File.expand_path("../", __FILE__) # For the 'spec/' mocks

  t.spec_files = FileList['spec/perforce2svn/**/*_spec.rb']
  t.spec_opts = ['-c', '-f', 'specdoc']
  t.fail_on_error = false
end

desc "Runs the integration tests"
Spec::Rake::SpecTask.new(:integration) do |t|
  t.libs << File.expand_path("../lib", __FILE__)
  t.libs << File.expand_path("../", __FILE__) # For the 'spec/' mocks

  t.spec_files = FileList['spec/integration/**/*_spec.rb']
  t.spec_opts = ['-c', '-f', 'specdoc']
  t.fail_on_error = false
end  

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version
    gem.name        = "perforce2svn"
    gem.platform    = Gem::Platform::RUBY
    gem.authors     = ["Gabe McArthur"]
    gem.email       = ["madeonamac@gmail.com"]
    gem.homepage    = "http://github.com/gabemc/perforce2svn"
    gem.summary     = "Converts a Perforce repository into a Subversion repository"
    gem.description = "It loads each revision in a Perforce repository sequentially and commits each change into an exist or new or existing Subversion repository.  It also handles more complicated operations that may occur after a migration, like adding, deleting, copy, or updating files to make the entire migration functional."
    gem.has_rdoc    = false
    
    gem.required_rubygems_version = ">=1.3.5"
    gem.rubyforge_project         = "perforce2svn"

    gem.add_dependency 'log4r',     '>=1.1.7'
    gem.add_dependency 'p4ruby',    '>=1.0.9'

    gem.add_development_dependency 'rspec', '>=1.3.0'
    gem.add_development_dependency 'mocha', '>=0.9.8'

    gem.files        = Dir.glob("**/*")
    gem.executables  = ['perforce2svn']
    gem.require_path = 'lib'
  end
rescue LoadError
  puts "You need 'jeweler' gem installed"
end
