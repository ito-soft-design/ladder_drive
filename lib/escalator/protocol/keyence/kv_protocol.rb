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

module Escalator
module Protocol
module Keyence

  class KvProtocol < Protocol

    def initialize options={}
      super
      @host = options[:host] || "192.168.0.10"
      @port = options[:port] || 8501
    end

    def open
      open!
    rescue
      nil
    end

    def open!
      @socket ||= TCPSocket.open(@host, @port)
    end

    def close
      @socket.close if @socket
      @socket = nil
    end

    def get_bit_from_device device
      device = device_by_name device
      get_bits_from_device(1, device).first
    end

    def get_bits_from_device count, device
      values = get_words_from_device count, device
      values.map{|v| v == 0 ? false : true}
    end

    def set_bits_to_device bits, device
      device = device_by_name device
      bits = [bits] unless bits.is_a? Array
      bits.each do |v|
        cmd = v ? "ST" : "RS"
        packet = "#{cmd} #{device.name}\r"
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet)
        #@socket.flush
        res = receive
        raise res unless /OK/i =~ res
        device += 1
      end
    end
    alias :set_bit_to_device :set_bits_to_device


    def get_word_from_device device
      device = device_by_name device
      get_words_from_device(1, device).first
    end

    def get_words_from_device(count, device)
      device = device_by_name device
      packet = "RDS #{device.name} #{count}\r"
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet)
      @socket.flush
      res = receive
      values = res.split(/\s/).map{|v| v.to_i}
      @logger.debug("get #{device.name} => #{values}")
      values
    end

    def set_words_to_device words, device
      device = local_device device
      words = [words] unless words.is_a? Array
      packet = "WRS #{device.name} #{words.size} #{words.map{|w| w.to_s}.join(" ")}\r"
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.puts(packet)
      res = receive
      raise res unless /OK/i =~ res
    end
    alias :set_word_to_device :set_words_to_device


    def device_by_name name
      case name
      when String
        device_class.new name
      else
        # it may be already Device
        name
      end
    end


    def receive
      res = ""
      begin
        Timeout.timeout(0.1) do
          res = @socket.gets
        end
      rescue Timeout::Error
      end
      @logger.debug("< #{dump_packet res}")
      res.chomp
    end

    def dump_packet packet
      packet.dup.chomp
    end

    private

      def local_device device
        # TODO:
        device
      end

      def device_class
        KvDevice
      end

  end

end
end
end
