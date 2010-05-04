require 'perforce2svn/mapping/parser'
require 'stringio'

module Perforce2Svn
  module Mapping

    module ParserHelper
      def parse(txt)
        p = Parser.new(StringIO.new(txt), 'live')
        p.parse_content
        p
      end
    end

    describe "Mapping file parser" do
      include ParserHelper

      it "should fail when an unknown directive is found" do
        parse(<<EOF
# A comment
not-directive arg
EOF
              ).parse_failed?.should be(true)
      end

      it "should be able to parse 'add's" do
        parse("add /some/path").parse_failed?.should be(false)
      end

      it "should be able to parse 'migrate'" do
        c = parse("migrate //depot/path /svn/path").mapping.branch_mappings
        c[0].class.should eql(BranchMapping)
        c[0].svn_path.should eql('/svn/path/')
      end

      it "should fail to parse the 'update' command without a svn prefix" do
        parse("update src/main/pom.xml").parse_failed?.should be(true)
      end

      it "should parse the 'update' command when an svn prefix is available" do
        c = parse(<<EOF
svn-prefix /some/path
update src/main/pom.xml
EOF
                  ).parse_failed?.should be(false)
      end


    end

  end
end
