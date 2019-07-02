# The MIT License (MIT)
#
# Copyright (c) 2019 ITO SOFT DESIGN Inc.
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


# Supported models : CP1E

module LadderDrive
module Protocol
module Omron

  class OmronDevice < PlcDevice

    attr_reader :suffix, :channel, :bit

    SUFFIXES = %w(M H D T C A)

    def initialize a, b = nil, c=nil
      case a
      when Array
=begin
        case a.size
        when 4
          @suffix = suffix_for_code(a[3])
          @channel = ((a[2] << 8 | a[1]) << 8) | a[0]
        end
=end
      else
        if b
          @suffix = a.upcase if a
          @channel = b.to_i
          @bit = c.to_i if c
        else
          if /^(M|H|D|T|C|A)?([0-9]+)(\.([0-9]{1,2}))?$/i =~ a
            @suffix = $1.upcase if $1
            @channel = $2.to_i
            @bit = $4.to_i if $4
          end
        end
      end
      case @suffix
      when "T", "C"
        raise "#{self.name} is not allowed as a bit device." if @bit
      end
    end

    def valid?
      !!@channel
    end

    def name
      if @bit
        "#{@suffix}#{@channel}.#{bit.to_s.rjust(2, '0')}"
      else
        "#{@suffix}#{@channel}"
      end
    end

    def next_device
      self + 1
    end

    def bit_device?
      !!@bit
    end

    def suffix_for_code code
      index = SUFFIX_CODES.index code
      index ? SUFFIXES[index] : nil
    end

    def suffix_code
      index = SUFFIXES.index suffix
      index ? SUFFIX_CODES[index] : 0
    end

    def + value
      if @bit
        v = @channel * 16 + @bit + value
        c = v / 16
        b = v % 16
        self.class.new @suffix, c, b
      else
        self.class.new @suffix, @channel + value
      end
    end

    def - value
      if @bit
        v = [@channel * 16 + @bit - value, 0].max
        c = v / 16
        b = v % 16
        self.class.new @suffix, c, b
      else
        self.class.new @suffix, [@channel - value, 0].max
      end
    end

  end

end
end
end
