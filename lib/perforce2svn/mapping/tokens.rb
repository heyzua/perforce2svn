
module Perforce2Svn
  module Mapping

    class Token
      attr_reader :value, :line

      def initialize(line, value)
        @value = value
        @line = line
      end
    end
  end
end
