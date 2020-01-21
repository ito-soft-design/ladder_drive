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

module LadderDrive
module Protocol

  class Protocol

    attr_accessor :host, :port

    def initialize options={}
      @logger = Logger.new(STDOUT)
      self.log_level = options[:log_level] || :info
    end

    def log_level
      @log_level
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

    TIMEOUT = 1.0

    # abstract methods

    def open; end
    def close; end

    def get_bit_from_device device; get_bits_from_device(1, device_by_name(device)).first; end
    def get_bits_from_device count, device; end
    def set_bit_to_device bit, device; set_bits_to_device [bit], device; end
    def set_bits_to_device bits, device; end

    def get_word_from_device device; get_words_from_device(1, device_by_name(device)).first; end
    def get_words_from_device count, device; end
    def set_word_to_device word, device; set_words_to_device [word], device; end
    def set_words_to_device words, device; end

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

    def available_bits_range device=nil
      -Float::INFINITY..Float::INFINITY
    end

    def available_words_range device=nil
      -Float::INFINITY..Float::INFINITY
    end

    def [] *args
      case args.size
      when 1
        # protocol["DM0"]
        # protocol["DM0".."DM9"]
        case args[0]
        when String
          self[args[0], 1].first
        when Range
          self[args[0].first, args[0].count]
        else
          raise ArgumentError.new("#{args[0]} must be String or Range.")
        end
      when 2
        # protocol["DM0", 10]
        d = device_by_name args[0]
        c = args[1]
        if d.bit_device?
          a = []
          b = available_bits_range(d).last
          until c == 0
            n_c = [b, c].min
            a += get_bits_from_device(n_c, d)
            d += n_c
            c -= n_c
          end
          a
        else
          a = []
          b = available_words_range(d).last
          until c == 0
            n_c = [b, c].min
            a += get_words_from_device(n_c, d)
            d += n_c
            c -= n_c
          end
          a
        end
      else
        raise ArgumentError.new("wrong number of arguments (given #{args.size}, expected 1 or 2)")
      end
    end

    def []= *args
      case args.size
      when 2
        # protocol["DM0"] = 0
        # protocol["DM0".."DM9"] = [0, 1, .., 9]
        v = args[1]
        v = [v] unless v.is_a? Array
        case args[0]
        when String
          self[args[0], 1] = v
        when Range
          self[args[0].first, args[0].count] = v
        else
          raise ArgumentError.new("#{args[1]} must be String or Array.")
        end
      when 3
        # protocol["DM0", 10] = [0, 1, .., 9]
        d = device_by_name args[0]
        c = args[1]
        values = args[2]
        values = [values] unless values.is_a? Array
        raise ArgumentError.new("Count #{c} is not match #{args[2].size}.") unless c == values.size
        if d.bit_device?
          a = []
          values.each_slice(available_bits_range(d).last) do |sv|
            set_bits_to_device(sv, d)
            d += sv.size
          end
          a
        else
          a = []
          values.each_slice(available_words_range(d).last) do |sv|
            set_words_to_device(sv, d)
            d += sv.size
          end
          a
        end
      else
        raise ArgumentError.new("wrong number of arguments (given #{args.size}, expected 2 or 3)")
      end
    end

    def destination_ipv4
      Socket.gethostbyname(self.host)[3].unpack("C4").join('.')
    end

    def self_ipv4
      Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
    end

  end

end
end

require 'serialport'
require 'keyence/keyence'
# Use load instead require, because there are two emulator files.
load File.join(dir, 'emulator/emulator.rb')
require 'mitsubishi/mitsubishi'
require 'omron/omron'
