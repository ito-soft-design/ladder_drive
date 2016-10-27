$:.unshift File.dirname(__FILE__)

module Protocol

  class Protocol

    attr_accessor :ip, :port

    def read_device device
      0
    end

    def write_value_to_device value, device
    end

  end

end

require 'mitsubishi/mc_protocol'
