$:.unshift File.dirname(__FILE__)

module Escalator
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

    # abstract methods
    
    def open; end
    def close; end

    def get_bit_from_device device; end
    def get_bits_from_device count, device; end
    def set_bits_to_device bits, device; end
    def set_bit_to_device bit, device; set_bits_to_device bit, device; end

    def get_word_from_device device; end
    def get_words_from_device(count, device); end
    def set_words_to_device words, device; end
    def set_word_to_device word, device; set_words_to_device word, device; end

    def device_by_name name; nil; end

  end

end
end

require 'mitsubishi/mitsubishi'
