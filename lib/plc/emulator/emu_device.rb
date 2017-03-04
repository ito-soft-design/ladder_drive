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

require 'escalator/plc_device'

include LadderDrive

module Plc
module Emulator

  class EmuDevice < PlcDevice

    attr_reader :in_value, :out_value

    def initialize a, b = nil
      super
      @lock = Mutex.new
      @in_value = 0
      @out_value = 0
    end

    def reset
      @lock.synchronize {
        super
        @in_value = nil
        @out_value = 0
      }
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
      @lock.synchronize { super }
    end

    def word kind=nil
      value kind
    end

    def word= value
      @lock.synchronize {
        super
      }
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
          @value = value
        end
      }
    end

    def sync_input
      @lock.synchronize {
        unless @in_value.nil?
          @value = @in_value
          @in_value = nil
        end
      }
    end

    def sync_output
      @lock.synchronize {
        @out_value = @value
      }
    end

  end

end
end
