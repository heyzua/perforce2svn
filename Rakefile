$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path("../spec", __FILE__)

require 'fileutils'
require 'rake'
require 'rubygems'
require 'rspec/core/rake_task'
require 'choosy/rake'

task :default => :spec
task :test => [:integration, :spec]

desc "Run the RSpec tests for the main perforce2svn tree"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/perforce2svn/**/*_spec.rb'
end

desc "Runs the integration tests"
RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end  

desc "Clean up"
task :clean => ['gem:clean']
