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

module LadderDrive
module Protocol
module Mitsubishi

  class McProtocol < Protocol

    def initialize options={}
      super
      @host = options[:host] || "192.168.0.10"
      @port = options[:port] || 5010
      prepare_device_map
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
      device = device_by_name device
      packet = make_packet(body_for_get_bits_from_deivce(count, device))
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet.pack("c*"))
      @socket.flush
      res = receive
      bits = []
      count.times do |i|
        v = res[11 + i / 2]
        if i % 2 == 0
          bits << ((v >> 4) != 0)
        else
          bits << ((v & 0xf) != 0)
        end
      end
      @logger.debug("get #{device.name} => #{bits}")
      bits
    end

    def set_bits_to_device bits, device
      device = device_by_name device
      packet = make_packet(body_for_set_bits_to_device(bits, device))
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet.pack("c*"))
      @socket.flush
      res = receive
      @logger.debug("set #{bits} to:#{device.name}")
    end


    def get_word_from_device device
      device = device_by_name device
      get_words_from_device(1, device).first
    end

    def get_words_from_device(count, device)
      device = device_by_name device
      packet = make_packet(body_for_get_words_from_deivce(count, device))
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet.pack("c*"))
      @socket.flush
      res = receive
      words = []
      res[11, 2 * count].each_slice(2) do |pair|
        words << pair.pack("c*").unpack("v").first
      end
      @logger.debug("get from: #{device.name} => #{words}")
      words
    end

    def set_words_to_device words, device
      device = device_by_name device
      packet = make_packet(body_for_set_words_to_device(words, device))
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.write(packet.pack("c*"))
      @socket.flush
      res = receive
      @logger.debug("set #{words} to: #{device.name}")
    end


    def device_by_name name
      case name
      when String
        QDevice.new name
      when EscDevice
        local_device_of name
      else
        # it may be already QDevice
        name
      end
    end


    def receive
      res = []
      len = 0
      begin
        Timeout.timeout(1.0) do
          loop do
            c = @socket.read(1)
            next if c.nil? || c == ""

            res << c.bytes.first
            len = res[7,2].pack("c*").unpack("v*").first if res.length >= 9
            break if (len + 9 == res.length)
          end
        end
      rescue Timeout::Error
        puts "*** ERROR: TIME OUT ***"
      end
      @logger.debug("< #{dump_packet res}")
      res
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
      a = []
      len = packet.length
      bytes = packet.dup
      len.times do |i|
        a << ("0" + bytes[i].to_s(16))[-2, 2]
      end
      "[" + a.join(", ") + "]"
    end

    def prepare_device_map
      @conv_dev_dict ||= begin
        h = {}
        [
          ["X", "X0", 1024],
          ["Y", "Y0", 1024],
          ["M", "M0", 1024],
          ["C", "C0", 256],
          ["T", "T0", 256],
          ["L", "L0", 1024],
          ["SC", "M1024", 1024],
          ["D", "D0", 1024],
          ["H", "D1024", 1024],
          ["SD", "D2048", 1024],
          ["PRG", "D3072", 1024]    # ..D4095
        ].each do |s,d,c|
          h[s] = [QDevice.new(d), c]
        end
        h
      end
    end

    def local_device_of device
      return device if device.is_a? QDevice
      d, c = @conv_dev_dict[device.suffix]
      return nil unless device.number < c
      ld = QDevice.new(d.suffix, d.number + device.number)
      device_by_name ld.name
    end

  end

end
end
end
