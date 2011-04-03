require 'spec_helpers'
require 'perforce2svn/mapping/branch_mapping'
require 'ostruct'

module Perforce2Svn::Mapping
  module BranchMappingHelper
    def map(p4, svn)
      tok = OpenStruct.new
      tok.line_number = 1
      BranchMapping.new(tok, p4, svn)
    end
  end

  describe "Branch Mappings" do
    include BranchMappingHelper

    it "should be able to determine when a path doesn't match" do
      bm = map('//depot/path/', '/svn/path/here')
      bm.matches_perforce_path?('//depot/not/here').should be(false)
    end

    it "should be able to determine when a path doesn't match" do
      bm = map('//depot/path/', '/svn/path/here')        
      bm.matches_perforce_path?('//depot/path/goes/here').should be(true)
    end

    it "should be able to format the dotted P4 path" do
      bm = map('//depot/path/', '/svn/path/here')
      bm.p4_dotted.should eql('//depot/path/...')
    end

    it "should be able to translate funky path characters correctly for subversion" do
      bf = map("//p/", "/o/")
      bf.to_svn_path("//p/%40/a").should eql("/o/@/a")
      bf.to_svn_path("//p/%23/a").should eql("/o/#/a")
      bf.to_svn_path("//p/%2a/a").should eql("/o/*/a")
      bf.to_svn_path("//p/%25/a").should eql("/o/%/a") 
    end
  end
end
