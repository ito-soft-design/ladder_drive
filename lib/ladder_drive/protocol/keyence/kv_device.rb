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

module LadderDrive
module Protocol
module Keyence

  class KvDevice < PlcDevice

    def initialize a, b = nil
      super
      @suffix = "R" if @suffix.nil? || @suffix.length == 0
    end

    def + value
      self.class.new self.suffix, self.number + value
    end

    def - value
      self.class.new self.suffix, [self.number - value, 0].max
    end

    private

      SUFFIXES_FOR_DEC      = %w(DM EM FM ZF TM Z T TC TS C CC CS CTH CTC AT CM VM)
      SUFFIXES_FOR_DEC_HEX  = %w(R MR LR CR)
      SUFFIXES_FOR_HEX      = %w(B VB W)
      SUFFIXES_FOR_BIT      = %w(R B MR LR CR VB)

      def suffixes_for_dec; SUFFIXES_FOR_DEC; end
      def suffixes_for_dec_hex; SUFFIXES_FOR_DEC_HEX; end
      def suffixes_for_hex; SUFFIXES_FOR_HEX; end
      def suffixes_for_bit; SUFFIXES_FOR_BIT; end

  end

end
end
end
