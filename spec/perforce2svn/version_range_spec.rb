require 'perforce2svn/version_range'
require 'spec_helpers'

module Perforce2Svn
  describe "Version Range information" do
    it "should sync to head when not given a max." do
      v1 = VersionRange.new(5)
      v1.should be_synced_to_head
    end
      
    it "should be able to reset to HEAD, once it is known" do
      v1 = VersionRange.new(5)
      v1.reset_to_head(1234)
      v1.max.should eql(1234)
    end

    it "can parse the #-# pair from the command line version information" do
      v1 = VersionRange.build("234:2345")
      v1.min.should eql(234)
      v1.max.should eql(2345)
    end
    
    it "can parse HEAD from the command line version version information" do
      v1 = VersionRange.build("1234:HEAD")
      v1.min.should eql(1234)
      v1.max.should eql(-1)
    end

    it "should fail on weird version input" do
      attempting { VersionRange.build("a:123")}.should raise_error(Choosy::ValidationError)
      attempting { VersionRange.build("123:b")}.should raise_error(Choosy::ValidationError)
    end
    
    it "should not allow negative numbers for the min revision" do
      attempting { VersionRange.build("-1:123")}.should raise_error(Choosy::ValidationError)
    end
    
    it "should not allow negative numbers for the max revision" do
      attempting { VersionRange.build("1:-4")}.should raise_error(Choosy::ValidationError)
    end
  end
end
