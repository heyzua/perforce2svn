require 'perforce2svn/errors'
require 'perforce2svn/subversion/svn_repo'
require 'spec_helpers'
require 'fileutils'

module Perforce2Svn::Subversion
  describe SvnRepo do
    include CommitHelper

    before :each do
      @repo = SvnRepo.new('REPO')
    end
    
    after :each do
      @repo.delete!
    end

    it 'should create a new repository upon initialization' do
      File.exists?(@repo.repository_path).should be(true)
      File.exists?(File.join(@repo.repository_path, 'hooks')).should be(true)
    end

    it 'should fail to create a transaction when a block is not given' do
      attempting { 
        @repo.transaction('me', Time.now, 'log') 
      }.should raise_error(Perforce2Svn::SvnTransactionError, /block-scoped/)
    end

    it "should be able to retrieve the file contents from a path" do
      write('/a', "this is some text")
      @repo.pull_contents('/a').should eql("this is some text")
    end

    it "should fail when the file contents don't exist" do
      attempting {
        @repo.pull_contents('/a')
      }.should raise_error(Svn::Error::FsNotFound, /revision 0/)
    end

    it "should fail when a file exists but not at a given revision" do
      write('/a', 'content')
      attempting {
        @repo.pull_contents('/a', 10)
      }.should raise_error(Svn::Error::FsNoSuchRevision, /10/)
    end

    it "should be able to determine when a path doesn't exist" do
      @repo.exists?('/a').should be_false
    end

    it "should be able to determine when a path exists" do
      write('/a', 'contents')
      @repo.exists?('/a').should be_true
    end

    it "should be able to retrieve the commit log" do
      write('/a', 'contents')
      commit = @repo.commit_log(1)
      commit.author.should eql('gabe')
    end

    it "should be fail to retrieve the commit log on a bad revision" do
      attempting {
        @repo.commit_log(10)
      }.should raise_error(Svn::Error::FsNoSuchRevision, /10/)
    end

    it "should be able to retrieve a property" do
      write('/a', 'contents', true)
      @repo.prop_get('/a', 'svn:mime-type', 1).should eql('application/octet-stream')
    end

    it "should be able to list child directories" do
      write('/a', 'contents')
      write('/b', 'contents')
      @repo.children('/').should eql(['a', 'b'])
    end

    it "should not retrieve properties on non-existent paths" do
      write('/a', 'contents')
      attempting {
        @repo.prop_get('/b', Svn::Core::PROP_REVISION_LOG)
      }.should raise_error(Svn::Error::FsNotFound, /\/b/)
    end

    it "should fail to retrieve properties on a bad revision" do
      write('/a', 'contents')
      attempting {
        @repo.prop_get('/a', Svn::Core::PROP_REVISION_AUTHOR, 5)
      }.should raise_error(Svn::Error::FsNoSuchRevision, /5/)
    end
  end
end
