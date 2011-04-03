require 'perforce2svn/logging'
require 'perforce2svn/mapping/analyzer'
require 'perforce2svn/mapping/commands'
require 'ostruct'

module Perforce2Svn::Mapping

  module AnalyzerHelper
    def analyzing(*commands)
      a = Analyzer.new(File.dirname(__FILE__))
      a.check(commands)
    end

    def updater(file = nil)
      file ||= __FILE__
      tok = OpenStruct.new
      tok.line_number = 1
      Update.new(tok, nil, file)
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

    it "should be able to check multiple files" do
      analyzing(updater("nowhere")).should be(false)
    end

    it "should be able to check when a file has a relative path" do
      analyzing(updater(File.basename(__FILE__))).should be(true)
    end
  end
end
