module Plc
module Emulator

  module DeviceType

    SUFFIXES = %w(X Y M - C T L SC CC TC D - CS TS H SD)

    SUFFIXES.each_with_index do |k, i|
      const_set :"#{k}", i unless k == '-'
    end

    attr_reader :device_type, :number

    def suffix
      s = SUFFIXES[device_type]
      s == '-' ? nil : s
    end

    def formatted_number
      case device_type
      when X, Y
        s = number.to_s(16)
        s = "0" + s unless /^\d/ =~ s
        s
      else
        number.to_i
      end
    end

  end

  class Device
    include DeviceType
    attr_reader :number

    attr_accessor :value

    class << self
      def parse name
        /^([a-z]+)(\d[0-9a-f]*)/i =~ name
        device_type = DeviceType::SUFFIXES.index $1
        case device_type
        when DeviceType::X, DeviceType::Y
          number = $2.to_i(16)
        else
          number = $2.to_i
        end
        new device_type, number
      end
    end

    def initialize device_type, number
      @device_type = device_type
      @number = number
    end

    def name
      "#{suffix}#{formatted_number}"
    end

    def input?
      device_type == X
    end

    def bool; !!value; end
    alias :bool= :value=
    alias :word :value
    alias :word= :value=

  end

end
end
