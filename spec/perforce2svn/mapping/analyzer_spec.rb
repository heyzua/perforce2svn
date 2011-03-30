require 'perforce2svn/logging'
require 'perforce2svn/mapping/analyzer'

module Perforce2Svn::Mapping

  module AnalyzerHelper
    def analyzing(*commands)
      a = Analyzer.new(Perforce2Svn::Logging.log, File.dirname(__FILE__))
      a.check(commands)
    end

    def adder(file = nil)
      file ||= __FILE__
      Add.new(Token.new(nil, 1), nil, file)
    end

    def updater(file = nil)
      file ||= __FILE__
      Update.new(Token.new(nil, 1), nil, file)
    end
  end

  describe "Mapping analyzer" do
    include AnalyzerHelper

    it "should be able to test whether updated files exist" do
      analyzing(updater).should be(true)
    end

    it "should fail when updated files don't exist" do
      analyzing(updater("nowhere")).should be(false)
    end

    it "should be able to locate added files" do
      analyzing(adder).should be(true)
    end

    it "should not be able to locate non-existent additions" do
      analyzing(adder("nowhere")).should be(false)
    end

    it "should be able to check multiple files" do
      analyzing(adder, updater("nowhere")).should be(false)
    end

    it "should be able to check when a file has a relative path" do
      analyzing(adder(File.basename(__FILE__))).should be(true)
    end
  end

end
