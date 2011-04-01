require 'perforce2svn/mapping/parser'
require 'stringio'

module Perforce2Svn
  module Mapping

    module ParserHelper
      def parse(txt)
        p = Parser.new
        p.parse!(StringIO.new(txt), 'live')
      end

      def mappings(txt)
        parse(txt)[:mappings]
      end

      def commands(txt)
        parse(txt)[:commands]
      end
    end

    describe "Mapping file parser" do
      include ParserHelper

      it "should fail when an unknown directive is found" do
        parse(<<EOF
# A comment
not-directive arg
EOF
              )[:failed].should be(true)
      end

      it "should be able to parse 'add's" do
        parse("add /some/path")[:failed].should be(false)
      end

      it "should be able to parse 'migrate'" do
        c = mappings("migrate //depot/path /svn/path")
        c[0].class.should eql(BranchMapping)
        c[0].line_number.should eql(1)
        c[0].svn_path.should eql('/svn/path/')
      end

      it "should fail to parse the 'update' command without a svn prefix" do
        parse("update src/main/pom.xml")[:failed].should be(true)
      end

      it "should parse the 'update' command when an svn prefix is available" do
        parse(<<EOF
svn-prefix /some/path
update src/main/pom.xml
EOF
                  )[:failed].should be(false)
      end

      it "should parse the mapping file and return a list of migrations" do
        m = mappings(<<EOF
migrate //depot/path /trunk/project
svn-prefix /trunk
migrate //depot/partition another-project
EOF
                  )

        first = m[0]
        first.line_number.should eql(1)
        first.p4_path.should eql('//depot/path/')
        first.svn_path.should eql('/trunk/project/')
        
        second = m[1]
        second.line_number.should eql(3)
        second.p4_path.should eql('//depot/partition/')
        second.svn_path.should eql('/trunk/another-project/')
      end

      it "should be able to correctly parse updates" do
        update = commands("update /src/dest.xml")[0]
        update.class.should eql(Update)
        update.line_number.should eql(1)
        update.live_path.should eql('live/src/dest.xml')
        update.svn_path.should eql('/src/dest.xml')
      end

      it "should be able to correctly parse remove" do
        delete = commands("remove /src/another.java")[0]
        delete.class.should eql(Remove)
        delete.line_number.should eql(1)
        delete.svn_path.should eql('/src/another.java')
      end

      it "should be able to correctly parse moves" do
        move = commands("move /this/location.txt /to/here/location.txt")[0]
        move.class.should eql(Move)
        move.line_number.should eql(1)
        move.svn_from.should eql('/this/location.txt')
        move.svn_to.should eql('/to/here/location.txt')        
      end

      it "should be able to correctly parse copies" do
        copy = commands("copy /src.txt /dest.txt")[0]
        copy.class.should eql(Copy)
        copy.line_number.should eql(1)
        copy.svn_from.should eql('/src.txt')
        copy.svn_to.should eql('/dest.txt')
      end

      it "should be able to inzert the svn prefix when a live path is calculated" do
        update = commands("svn-prefix /trunk/project\nupdate src/dest.xml")[0]
        update.live_path.should eql('live/trunk/project/src/dest.xml')
        update.svn_path.should eql('/trunk/project/src/dest.xml')
      end

      it "should be able to order the commands" do
        cmds = commands(<<EOF
update /src/dest.xml
remove /src/another.java
EOF
                        )
        
        cmds[0].class.should eql(Update)
        cmds[0].line_number.should eql(1)
        cmds[1].class.should eql(Remove)
        cmds[1].line_number.should eql(2)
      end

    end
  end
end
