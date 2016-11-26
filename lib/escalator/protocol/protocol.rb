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

dir = File.expand_path(File.dirname(__FILE__))
$:.unshift dir unless $:.include? dir

module Escalator
module Protocol
end
end

module Escalator
module Protocol

  class Protocol

    attr_accessor :host, :port, :log_level

    def initialize options={}
      @logger = Logger.new(STDOUT)
      self.log_level = options[:log_level] || :info
    end

    def log_level= level
      @log_level = level.is_a?(String) ? level.to_sym : level
      case @log_level
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

    def get_from_devices device, count = 1
      d = device_by_name device
      if d.bit_device?
        get_bits_from_device count, d
      else
        get_words_from_device count, d
      end
    end

    def set_to_devices device, values
      values = [values] unless values.is_a? Array
      d = device_by_name device
      if d.bit_device?
        values = values.map{|v| case v;  when 1; true; when 0; false; else; v; end}
        set_bits_to_device values, d
      else
        set_words_to_device values, d
      end
    end

  end

end
end

require 'keyence/keyence'
# Use load instead require, because there are two emulator files.
load File.join(dir, 'emulator/emulator.rb')
require 'mitsubishi/mitsubishi'
