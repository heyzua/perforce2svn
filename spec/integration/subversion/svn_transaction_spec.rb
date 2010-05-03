require 'perforce2svn/subversion/svn_repo'
require 'stringio'

class StringIO
  def readpartial(len)
    read(len)
  end
end

module Perforce2Svn
  module Subversion

    module CommitHelper
      def write(path, text, binary = false)
        @repo.transaction('gabe', Time.now, "Committing to : #{path}") do |txn|
          contents = StringIO.new(text)
          txn.add(path, contents, binary)
        end
      end
      def delete(path)
        @repo.transaction('gabe', Time.now, "Deleting: #{path}") do |txn|
          txn.delete(path)
        end
      end
      def symlink(src, dest)
        @repo.transaction('gabe', Time.now, "Symlinking: #{src} to #{dest}") do |txn|
          txn.symlink(src, dest)
        end
      end
      def read_in(local_path, mode = nil)
        mode ||= 'r'
        f = open(local_path, mode)
        contents = f.read
        f.close
        contents
      end
    end

    describe "Subversion Transaction" do
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
        lambda { @repo.pull_contents('/a') }.should raise_error
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
    end
  end
end
