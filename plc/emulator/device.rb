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

    def initialize device_type, number
      @device_type = device_type
      @number = number
    end

    def name
      "#{suffix}#{formatted_number}"
    end

  end

end
end
