require 'perforce2svn/cli'
require 'perforce2svn/errors'
require 'spec_helpers'

module Perforce2Svn
  module CLIHelper
    def parse(*args)
      cli = CLI.new
      args << '--repository'
      args << 'here'
      args << __FILE__
      cli.parse!(args, true)
    end
  end

  describe CLI do
    include CLIHelper

    it "should be able to parse the debug flag correctly" do
      parse("--debug")[:debug].should be(true)
    end

    it "should be able to retrieve the repository path" do
      parse('-r', 'some/path')[:repository].should eql('here')
    end

    it "should be able to parse the live path" do
      parse('-l', '/')[:live_path].should eql('/')
    end

    it "should be able to skip updates" do
      parse('--skip-updates')[:skip_updates].should be(true)
    end

    it "should be able to skip perforce" do
      parse('--skip-perforce')[:skip_perforce].should be(true)
    end

    it "should be able to run the analysis only" do
      parse('-a')[:analyze_only].should be(true)
    end

    describe "when validating the count format" do
      it "should fail when the start revision is less than 1" do
        attempting_to { 
          parse('-c', '0:4') 
        }.should raise_error(Choosy::ClientExecutionError, /--changes/)
      end

      it "should set -1 when given HEAD" do
        parse('-c', '1:HEAD')[:change_end].should eql(-1)
      end

      it "should fail when the end revision < 1" do
        attempting_to {
          parse('-c', '1:0')
        }.should raise_error(Choosy::ClientExecutionError, /end with/)
      end
    end
  end
end
