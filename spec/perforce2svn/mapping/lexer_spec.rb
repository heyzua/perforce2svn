require 'perforce2svn/mapping/lexer'

module Perforce2Svn
  module Mapping

    describe "Mapping lexer" do
      it "should be able to parse a set of simple tokens in a line" do
        lexer = Lexer.new(nil)
        tok = lexer.tokenize('migrate this/that other/file')
        tok.length.should eql(3)
        tok[0].should eql('migrate')
        tok[1].should eql('this/that')
        tok[2].should eql('other/file')
      end

      it "should handle spaces in the path names" do
        lexer = Lexer.new(nil)
        tok = lexer.tokenize("migrate this/that\\ other/path will\\ be/something")
        tok.length.should eql(3)
        tok[0].should eql('migrate')
        tok[1].should eql("this/that other/path")
        tok[2].should eql("will be/something")
      end

      it "will delete multiple spaces" do
        lexer = Lexer.new(nil)
        tok = lexer.tokenize("     migrate     this/that     and/a\\ nother   ");
        tok.length.should eql(3)
        tok[0].should eql('migrate')
        tok[1].should eql('this/that')
        tok[2].should eql('and/a nother')
      end

      it "should leave off the comments at the end of lines" do
        lexer = Lexer.new(nil)
        tok = lexer.tokenize("this is a # comment string")
        tok.length.should eql(3)
        tok[0].should eql('this')
        tok[2].should eql('a')
      end
    end
  end
end
