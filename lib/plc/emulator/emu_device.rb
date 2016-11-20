require 'escalator/plc_device'

include Escalator

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
        if @in_value
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
