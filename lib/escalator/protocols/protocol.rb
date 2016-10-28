$:.unshift File.dirname(__FILE__)

module Protocol

  class Protocol

    attr_accessor :host, :port

    def initialize options={}
      @logger = Logger.new(STDOUT)
      @logger.level = options[:log_level] || Logger::INFO
    end

    def log_level= level
      case level
      when :debug
        @logger.level = Logger::DEBUG
      when :error
        @logger.level = Logger::ERROR
      when :fatal
        @logger.level = Logger::FATAL
      when :info
        @logger.level = Logger::INFO
      when :unknown
        @logger.level = Logger::UNKNOWN
      when :warn
        @logger.level = Logger::WARN
      end
    end

    def read_device device
      0
    end

    def write_value_to_device value, device
    end

  end

end

require 'mitsubishi/mitsubishi'
