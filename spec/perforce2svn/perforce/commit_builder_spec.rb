require 'spec_helpers'
require 'perforce2svn/perforce/commit_builder'
require 'perforce2svn/mapping/commands'
require 'ostruct'

module Perforce2Svn::Perforce
  describe CommitBuilder do
    before :each do
      o = OpenStruct.new
      o.line = 1
      @mappings = [Perforce2Svn::Mapping::BranchMapping.new(o, "//some/path", "/trunk/project")]
      @builder = CommitBuilder.new(@mappings)
    end

    context "when building commit objects" do
      before :each do
        @commit = @builder.build_from({'change' => 1,
                                       'user' => 'gabe', 
                                       'desc' => "A log\r\ngoes here", 
                                       'depotFile' => ['//some/path/1', '//no/match'], 
                                       'action' => ['edit', 'create'], 
                                       'type' => ['text', 'binary'], 
                                       'time' => '1266433914', 
                                       'rev' => ['10', '2']})
      end

      it "should retrieve the correct time" do
        @commit.time.to_svn_format.should eql('2010-02-17T19:11:54.000000Z')
      end

      it "should reitrieve the user" do
        @commit.author.should eql('gabe')
      end
      
      it "should retrieve the revision" do
        @commit.revision.should eql(1)
      end

      it "should fix the log message" do
        @commit.log.should eql("A log\ngoes here")
      end

      it "should filter out the unnecessary files" do
        @commit.files.size.should eql(1)
      end

      context "and filling in child file information" do
        before :each do
          @file = @commit.files[0]
        end

        it "should set the file revision" do
          @file.revision.should eql(10)
        end

        it "should set the file source" do
          @file.src.should eql('//some/path/1')
        end

        it "should set the destination" do
          @file.dest.should eql('/trunk/project/1')
        end

        it "should set the type" do
          @file.type.should eql('text')
        end

        it "should set the action" do
          @file.action.should eql('edit')
        end
      end
    end
  end
end
