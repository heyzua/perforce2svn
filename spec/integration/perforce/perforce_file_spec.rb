require 'spec_helpers'
require 'perforce2svn/perforce/perforce_file'
require 'yaml'

module Perforce2Svn::Perforce
  describe PerforceFile do
    before :each do
      config_file = File.join(File.dirname(__FILE__), 'perforce_file.yml')
      @config = YAML::load_file(config_file)
      @file = PerforceFile.new(@config['revision'], @config['path'], nil, 'text', 'add')
    end

    it "should be able to retrieve file contents." do
      @file.contents.should match(Regexp.compile(@config['match']))
    end

    it "should locate the symlink"
  end
end
