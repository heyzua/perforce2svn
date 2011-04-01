require 'spec_helpers'
require 'perforce2svn/perforce/p4_depot'

module Perforce2Svn::Perforce
  describe P4Depot do
    it "should be able to connect to the Perforce server" do
      attempting {
        P4Depot.instance.connect!
      }.should_not raise_error
    end

    it "should be able to retrieve the latest revision" do
      P4Depot.instance.latest_revision.should >= 8000
    end
  end
end
