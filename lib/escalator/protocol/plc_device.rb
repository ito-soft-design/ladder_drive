# The MIT License (MIT)
#
# Copyright (c) 2016 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Escalator
module Protocol

  class PlcDevice

    attr_reader :suffix, :number

    NUMBER_TYPE_DEC     = 0
    NUMBER_TYPE_DEC_HEX = 1
    NUMBER_TYPE_HEX     = 2

    def initialize a, b = nil
      case a
      when String
        if b
          @suffix = a.upcase
          @number = b
        else
          /([A-Z]+)(\d+)/i =~ a
          @suffix = $1 || "R"
          case number_type
          when NUMBER_TYPE_DEC
            @number = $2.to_i
          when NUMBER_TYPE_DEC_HEX
            n = $2.to_i
            @number = (n / 100) * 16 + (n % 100)
          when NUMBER_TYPE_HEX
            @number = $2.to_i(16)
          end
        end
      end
    end

    def name
      case number_type
      when NUMBER_TYPE_DEC
        "#{@suffix}#{@number}"
      when NUMBER_TYPE_DEC_HEX
        a = [@number / 16, @number % 16]
        ns = begin
          s = a.last.to_s.rjust(2, "0")
          s = a.first.to_s + s unless a.first == 0
          s
        end
        "#{@suffix}#{ns}"
      when NUMBER_TYPE_HEX
        ns = @number.to_s(16)
        ns = "0" + ns unless /^[0-9]/ =~ ns
        "#{@suffix}#{ns}"
      else
        nil
      end
    end

    def next_device
      d = self.class.new @suffix, @number + 1
      d
    end

    def bit_device?
      SUFFIXES_FOR_BIT.include? @suffix
    end

    def + value
      self.class.new self.suffix, self.number + value
    end

    def - value
      self.class.new self.suffix, [self.number - value, 0].max
    end

    private

      SUFFIXES_FOR_DEC      = %w(M C T L SC CC TC D CS TS H SD)
      SUFFIXES_FOR_DEC_HEX  = %w()
      SUFFIXES_FOR_HEX      = %w(X Y)
      SUFFIXES_FOR_BIT     = %w(X Y M C T L SC)

      def suffixes_for_dec; SUFFIXES_FOR_DEC; end
      def suffixes_for_dec_hex; SUFFIXES_FOR_DEC_HEX; end
      def suffixeds_for_hex; SUFFIXES_FOR_HEX; end
      def suffixes_for_bit; SUFFIXES_FOR_BIT; end

      def suffixes
        suffixes_for_dec + suffixes_for_dec_hex + suffixeds_for_hex
      end

      def number_type
        return NUMBER_TYPE_DEC if suffixes_for_dec.include? @suffix
        return NUMBER_TYPE_DEC_HEX if suffixes_for_dec_hex.include? @suffix
        return NUMBER_TYPE_HEX if suffixes_for_hex.include? @suffix
        nil
      end

  end

  class EscDevice < PlcDevice; end

end
end
