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
        @socket.flush
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
      words = [words] unless words.is_a? Array
      packet = "WRS #{device.name} #{words.size} #{words.map{|w| w.to_s}.join(" ")}\r"
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet)
      @socket.flush
      res = receive
      raise res unless /OK/i =~ res
    end
    alias :set_word_to_device :set_words_to_device


    def device_by_name name
      case name
      when String
        KVDevice.new name
      else
        # it may be already QDevice
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

  private

    def make_packet body
      header = [0x50, 0x00,  0x00,  0xff,  0xff, 0x03,  0x00,  0x00, 0x00,  0x10,  0x00]
      header[7..8] = data_for_short(body.length + 2)
      header + body
    end

    def body_for_get_bit_from_deivce device
      body_for_get_bits_from_deivce 1, device
    end

    def body_for_get_bits_from_deivce count, device
      body_for_get_words_from_deivce count, device, false
    end

    def body_for_get_words_from_deivce count, device, word = true
      body = [0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
      body[2] = 1 unless word
      body[4..7] = data_for_device(device)
      body[8..9] = data_for_short count
      body
    end


    def body_for_set_bits_to_device bits, device
      body = [0x01, 0x14, 0x01, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
      d = device
      bits = [bits] unless bits.is_a? Array
      bits.each_slice(2) do |pair|
        body << (pair.first ? 0x10 : 0x00)
        body[-1] |= (pair.last ? 0x1 : 0x00) if pair.size == 2
        d = d.next_device
      end
      body[4..7] = data_for_device(device)
      body[8..9] = data_for_short bits.size
      body
    end
    alias :body_for_set_bit_to_device :body_for_set_bits_to_device

    def body_for_set_words_to_device words, device
      body = [0x01, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
      d = device
      words = [words] unless words.is_a? Array
      words.each do |v|
        body += data_for_short v
        d = d.next_device
      end
      body[4..7] = data_for_device(device)
      body[8..9] = data_for_short words.size
      body
    end

    def data_for_device device
      a = data_for_int device.number
      a[3] = device.suffix_code
      a
    end

    def data_for_short value
      [value].pack("v").unpack("c*")
    end

    def data_for_int value
      [value].pack("V").unpack("c*")
    end

    def dump_packet packet
      packet.dup.chomp
    end

  end

end
end
end
