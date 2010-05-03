require 'perforce2svn/mapping/parser'
require 'stringio'

module Perforce2Svn
  module Mapping

    module ParserHelper
      def parse(txt)
        p = Parser.new(StringIO.new(txt))
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
              ).failed.should be(true)
      end

      it "should be able to parse 'add's" do
        parse(<<EOF
add /some/path
EOF
              ).failed.should be(false)
      end

    end

  end
end
