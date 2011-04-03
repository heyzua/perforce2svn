
module Perforce2Svn
  module Mapping
    class Token
      attr_reader :name, :args, :line_number

      def initialize(name, args, line_number)
        @name = name.gsub(/-/, '_')
        @args = args
        @line_number = line_number
      end

      def [](index)
        @args[index]
      end

      def to_s
        "{@(#{line_number}) name: #{name}; args: #{args.join(' ')} }"
      end
    end

    class Lexer
      def initialize(content)
        @content = content
      end
      
      # Yields each parsed line of the configuration
      def each(&block)
        if not block_given?
          raise ArgumentError, "Requires a block"
        end

        lines = @content.readlines
        i = 1
        continues_from_previous = false
        previous = []
        
        lines.each do |line|
          parts= tokenize(line)

          will_continue_on_next_line = false
          if line =~ /\\\s*$/
            will_continue_on_next_line = true
          end

          if parts.length > 0
            if continues_from_previous
              previous << parts
            else
              previous = []
              name = parts.shift
              yield Token.new(name, parts, i)
            end
          end

          continues_from_previous = will_continue_on_next_line
          i += 1
        end
      end

      # Reads a line for all of the possible tokens
      def tokenize(line)
        chars = line.scan(/./)
        parts = []
        
        part = ""
        i = 0
        while i < chars.length
          current = chars[i]
          if current == '\\'
            nxt = chars[i + 1]
            if nxt == ' '
              i += 1
              part << ' '
            elsif nxt == "\n"
              break
            end
          elsif current == ' '
            if part.length > 0
              parts << part
              part = ""
            end
          elsif current == '#'
            break
          else
            part << current
          end

          i += 1
        end

        if not parts[-1].eql?(part)
          parts << part
        end

        parts.delete_if {|p| p =~ /^\s*$/}
        parts
      end
    end
  end
end
