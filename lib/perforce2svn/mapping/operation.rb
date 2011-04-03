module Perforce2Svn::Mapping
  class Operation
    attr_reader :line_number
    def initialize(tok)
      @line_number = tok.line_number
    end
  end
end
