require 'perforce2svn/errors'
require 'perforce2svn/subversion/svn_repo'
require 'fileutils'

module Perforce2Svn
  module Subversion

    module SvnRepoBuilder
      def create
        SvnRepo.new('REPO')
      end
      def clean!
        FileUtils.rm_rf 'REPO'
      end
    end

    describe 'Svn Repository' do
      include SvnRepoBuilder

      before :each do
        clean!
      end
      
      after :each do
        clean!
      end

      it 'should create a new repository upon initialization' do
        repo = create
        File.exists?(repo.repository_path).should be(true)
        File.exists?(File.join(repo.repository_path, 'hooks')).should be(true)
      end

      it 'should fail to create a transaction when a block is not given' do
        lambda { create.transaction('me', Time.now, 'log') }.should raise_error(Perforce2Svn::SvnTransactionError)
      end
    end

  end
end
