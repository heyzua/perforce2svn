require 'perforce2svn/subversion/svn_repo'
require 'spec_helpers'
require 'stringio'

module Perforce2Svn::Subversion
  describe SvnTransaction do
    include CommitHelper

    before :each do
      @repo = SvnRepo.new('REPO')
    end

    after :each do
      @repo.delete!
    end

    it "should be able to commit a single change" do
      write('/a.txt', "this is some text\nthat\goes here")
      @repo.pull_contents('/a.txt').should eql("this is some text\nthat\goes here")
    end

    it "should be able to retrieve the updated file contents" do
      write("/a.txt", "first commit")
      write("/a.txt", 'second commit')
      @repo.pull_contents('/a.txt').should eql('second commit')
    end

    it "should be able to delete a file" do
      write('/a', 'conent')
      delete('/a')
      attempting { 
        @repo.pull_contents('/a') 
      }.should raise_error
    end

    it "can create multiple directories" do
      @repo.exists?('/a/b/c').should be(false)

      @repo.transaction('g', Time.new, 'l') do |txn|
        txn.exists?('/a/b/c').should be(false)
        txn.mkdir('/a/b/c')
      end

      @repo.exists?('/a/b/c').should be(true)
    end

    it "can delete all parent directories" do
      write('/a/b/c/d.txt', 'some text')
      write('/a/b.txt', 'other text')
      delete('/a/b/c/d.txt')

      @repo.exists?('/a/b/c').should be(false)
    end

    it "will write binary mime types correctly" do
      jpg = read_in('spec/integration/madmen_icon_bigger.jpg', 'rb')
      write('/a.jpg', jpg, true)

      @repo.pull_contents('/a.jpg').should eql(jpg)
      @repo.prop_get('/a.jpg', 'svn:mime-type').should eql('application/octet-stream')
    end

    it "will make sure that big files are retained correctly" do
      hamlet = read_in('spec/integration/hamlet.txt')
      write('/hamlet.txt', hamlet)

      @repo.pull_contents('/hamlet.txt').should eql(hamlet)
    end

    it "will handle symlinks correctly" do
      write("/src.txt", "some content")
      symlink('./src.txt', '/b.txt')

      @repo.pull_contents('/b.txt').should eql('link ./src.txt')
      @repo.prop_get('/b.txt', 'svn:special').should eql('*')
    end

    it "will return the most recent revision number on commit" do
      write('/a.txt', 'content').should eql(1)
    end

    it "will be able to find if a directory has children" do
      write('/a/b.txt', 'content')
      write('/a/c.txt', 'content')
      @repo.transaction('gabe', Time.now, 'r') do |txn|
        txn.has_children?('/a').should be(true)
      end
    end

    it "will be able to copy paths" do
      write('/a.txt', 'content')
      @repo.transaction('gabe', Time.now, 'r') do |txn|
        txn.copy('/a.txt', '/b.txt')
      end

      @repo.exists?('/a.txt').should be_true
      @repo.exists?('/b.txt').should be_true
      @repo.pull_contents('/b.txt').should eql('content')
    end

    it "will be able to move paths" do
      write('/a.txt', 'content')
      @repo.transaction('gabe', Time.now, 'r') do |txn|
        txn.move('/a.txt', '/b.txt')
      end

      @repo.exists?('/a.txt').should be_false
      @repo.exists?('/b.txt').should be_true
      @repo.pull_contents('/b.txt').should eql('content')
    end
  end
end
