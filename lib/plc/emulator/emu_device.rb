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

require 'ladder_drive/plc_device'
require 'weakref'

include LadderDrive

module Plc
module Emulator

  class EmuDevice < PlcDevice

    attr_reader :in_value, :out_value
    attr_accessor :plc

    def initialize a, b = nil
      super
      @lock = Mutex.new
      @in_value = 0
      @out_value = 0
      @changed = false
    end

    def reset
      @lock.synchronize {
        super
        @in_value = nil
        @out_value = 0
      }
    end

    def plc= plc
      @plc = WeakRef.new plc
    end

    def changed?
      @changed
    end

    # NOTE: override at subclass
    #       It should get from plc
    def device_by_suffix_number suffix, number
      d = super
      plc.device_by_name d.name
    end

    def value= value
      set_value value
    end

    def bool kind=nil
      v = value kind
      case v
      when nil, false, 0
        false
      else
        true
      end
    end

    def bool= value
      set_value value
    end

    def word kind=nil
      if bit_device?
        v = 0
        d = self
        f = 1
        16.times do
          v |= f if d.bool(kind)
          d = d + 1
          f <<= 1
        end
        v
      else
        value kind
      end
    end

    def word= value
      set_word value
    end

    def set_word value, kind=nil
      if bit_device?
        f = 1
        d = self
        16.times do
          d.set_value (value & f) != 0, kind
          d = d + 1
          f <<= 1
        end
      else
        set_value value, kind
      end
    end

    def value kind=nil
      @lock.synchronize {
        case kind
        when :in
          @in_value
        when :out
          @out_value
        else
          @value
        end
      }
    end

    def set_value value, kind=nil
      @lock.synchronize {
        case kind
        when :in
          @in_value = value
        when :out
          @out_value = value
        else
          @changed = true unless @value == value
          @value = value if @changed
        end
      }
    end

    def sync_input
      @lock.synchronize {
        unless @in_value.nil?
          @changed = true unless @value == @in_value
          @value = @in_value if @changed
          @in_value = nil
        end
      }
    end

    def sync_output
      @lock.synchronize {
        @out_value = @value
        @changed = false
      }
    end

    def + value
      d = super
      plc ? plc.device_by_name(d.name) : d
    end

    def - value
      d = super
      plc ? plc.device_by_name(d.name) : d
    end

  end

end
end
