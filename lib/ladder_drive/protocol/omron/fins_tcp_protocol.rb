# The MIT License (MIT)
#
# Copyright (c) 2019 ITO SOFT DESIGN Inc.
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
module Omron

  class FinsTcpProtocol < Protocol

    attr_accessor :gateway_count
    attr_accessor :destination_network
    attr_accessor :destination_node
    attr_accessor :destination_unit
    attr_accessor :source_network
    attr_accessor :source_node
    attr_accessor :source_unit

    attr_accessor :ethernet_module

    attr_accessor :tcp_error_code

    IOFINS_DESTINATION_NODE_FROM_IP = 0
    IOFINS_SOURCE_AUTO_NODE         = 0

    # Available ethernet module.
    ETHERNET_ETN21  = 0
    ETHERNET_CP1E   = 1
    ETHERNET_CP1L   = 2
    ETHERNET_CP1H   = 3

    def initialize options={}
      super
      @socket = nil
      @host = options[:host] || "192.168.250.1"
      @port = options[:port] || 9600
      @gateway_count = 3
      @destination_network = 0
      @destination_node = 0
      @destination_unit = 0
      @source_network = 0
      @source_node = IOFINS_SOURCE_AUTO_NODE
      @source_unit = 0
      @ethernet_module = ETHERNET_ETN21

      @tcp_error_code = 0

      prepare_device_map
    end

    def open
      open!
    rescue =>e
p e
      nil
    end

    def open!
      if @socket.nil?
        @socket = TCPSocket.open(@host, @port)
        if @socket
          source_node = IOFINS_SOURCE_AUTO_NODE
          query_node
        end
      end
      @socket
    end

    def close
      @socket.close if @socket
      @socket = nil
    end

    def tcp_error?
      tcp_error_code != 0
    end

    def create_query_node
      header = [ "FINS".bytes.to_a,  0, 0, 0, 0xc,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0].flatten
      header[19] = source_node == IOFINS_SOURCE_AUTO_NODE ? 0 : source_node
      header
    end

    def create_fins_frame packet
      packet = packet.flatten
      header = [ "FINS".bytes.to_a,  0, 0, 0, 0,  0, 0, 0, 2,  0, 0, 0, 0].flatten
      header[4, 4] = int_to_a(packet.length + 8, 4)
      header + packet
    end

    def get_bits_from_device(count, device)
      open
      raise ArgumentError.new("A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}") unless available_bits_range.include? count

      device = device_by_name device
      raise ArgumentError.new("#{device.name} is not bit device!") unless device.bit_device?

      command = [1, 1]
      command << device_to_a(device)
      command << int_to_a(count, 2)

      send_packet create_fins_frame(fins_header + command)
      res = receive

      count.times.inject([]) do |a, i|
        a << (res[16 + 10 + 4 + i] == 0 ? false : true)
        a
      end
    end

    def get_words_from_device(count, device)
      open
      raise ArgumentError.new("A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}") unless available_words_range.include? count

      device = device_by_name device
      device = device.channel_device

      command = [1, 1]
      command << device_to_a(device)
      command << int_to_a(count, 2)

      send_packet create_fins_frame(fins_header + command)
      res = receive
      count.times.inject([]) do |a, i|
        a << to_int(res[16 + 10 + 4 + i * 2, 2])
        a
      end
    end

    def set_bits_to_device(bits, device)
      open
      count = bits.size
      raise ArgumentError.new("A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}") unless available_bits_range.include? count

      device = device_by_name device
      raise ArgumentError.new("#{device.name} is not bit device!") unless device.bit_device?

      command = [1, 2]
      command << device_to_a(device)
      command << int_to_a(count, 2)
      bits.each do |b|
        command << (b ? 1 : 0)
      end

      send_packet create_fins_frame(fins_header + command)
      res = receive
    end

    def set_words_to_device(words, device)
      open
      count = words.size
      raise ArgumentError.new("A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}") unless available_words_range.include? count

      device = device_by_name device
      device = device.channel_device

      command = [1, 2]
      command << device_to_a(device)
      command << int_to_a(count, 2)
      words.each do |w|
        command << int_to_a(w, 2)
      end

      send_packet create_fins_frame(fins_header + command)
      res = receive
    end

    def query_node
      send_packet create_query_node
      res = receive
      self.source_node = res[19]
    end


    def send_packet packet
      @socket.write(packet.flatten.pack("c*"))
      @socket.flush
      @logger.debug("> #{dump_packet packet}")
    end

    def receive
      res = []
      len = 0
      begin
        Timeout.timeout(5.0) do
          loop do
            c = @socket.getc
            next if c.nil? || c == ""

            res << c.bytes.first
            next if res.length < 8

            len = to_int(res[4, 4])
            next if res.length < 8 + len

            tcp_command = to_int(res[8, 4])
            case tcp_command
            when 3 # ERROR
              raise "Invalidate tcp header: #{res}"
            end
            break
          end
        end
        raise "Response error code: #{res[15]}" unless res[15] == 0
        res
      end
      @logger.debug("< #{dump_packet res}")
      res
    end

    # max length:
    #  CS1W-ETN21, CJ1W-ETN21   : 2012
    #  CP1W-CIF41 option board  : 540 (1004 if cpu is CP1L/H)

    def available_bits_range device=nil
      case ethernet_module
      when ETHERNET_ETN21
        1..(2012 - 8)
      when ETHERNET_CP1E
        1..(540 - 8)
      when ETHERNET_CP1L, ETHERNET_CP1H
        1..(1004 - 8)
      else
        0..0
      end
    end

    def available_words_range device=nil
      case ethernet_module
      when ETHERNET_ETN21
        1..((2012 - 8) / 2)
      when ETHERNET_CP1E
        1..((540 - 8) / 2)
      when ETHERNET_CP1L, ETHERNET_CP1H
        1..((1004 - 8) / 2)
      else
        0..0
      end
    end

    def device_by_name name
      case name
      when String
        d = OmronDevice.new name
        d.valid? ? d : nil
      when EscDevice
        local_device_of name
      else
        # it may be already OmronDevice
        name
      end
    end

    private

    def fins_header
      buf = [
              0x80, # ICF
              0x00, # RSV
              0x02, # GCT
              0x00, # DNA
              0x01, # DA1
              0x00, # DA2
              0x00, # SNA
              0x01, # SA1
              0x00, # SA2
              0x00, # SID
            ]
      buf[2] = gateway_count - 1
      buf[3] = destination_network
      if destination_node == IOFINS_DESTINATION_NODE_FROM_IP
        buf[4] = destination_ipv4.split(".").last.to_i
      else
        buf[4] = destination_node
      end
      buf[7] = source_node
      buf[8] = source_unit

      buf
    end

    def fins_tcp_cmnd_header
      header = [ "FINS".bytes.to_a,  0, 0, 0, 0xc,  0, 0, 0, 2,  0, 0, 0, 0].flatten
      header[19] = source_node == IOFINS_SOURCE_AUTO_NODE ? 0 : source_node
      header
    end

    def device_code_of device
      @@bit_codes ||= { nil => 0x30, "" => 0x30, "W" => 0x31, "H" => 0x32, "A" => 0x33, "T" => 0x09, "C" => 0x09, "D" => 0x02, "E" => 0x0a, "TK" => 0x06 }
      @@word_codes ||= { nil => 0xB0, "" => 0xB0, "W" => 0xB1, "H" => 0xB2, "A" => 0xB3, "TIM" => 0x89, "CNT" => 0x89, "D" => 0x82, "E" => 0x98, "DR" => 0xbc }
      if device.bit_device?
        @@bit_codes[device.suffix]
      else
        @@word_codes[device.suffix]
      end
    end

    def device_to_a device
      a = []
      a << device_code_of(device)
      a << int_to_a(device.channel, 2)
      a << (device.bit_device? ? (device.bit || 0) : 0)
      a.flatten
    end


    # FIXME: It's dummy currently.
    def prepare_device_map
      @conv_dev_dict ||= begin
        h = {}
        [
          ["X", "0.0", 1024],
          ["Y", "400.0", 1024],
          ["M", "M0.0", 1024],
          ["C", "C0", 256],
          ["T", "T0", 256],
          ["L", "H0.0", 1024],
          ["SC", "M400.0", 1024],
          ["D", "D0", 1024],
          ["H", "D1024", 1024],
          ["SD", "D2048", 1024],
          ["PRG", "D3072", 1024]    # ..D4095
        ].each do |s,d,c|
          h[s] = [OmronDevice.new(d), c]
        end
        h
      end
    end

    def int_to_a value, size
      a = []
      (size - 1).downto 0 do |i|
        a << ((value >> (i * 8)) & 0xff)
      end
      a
    end

    def to_int a
      v = 0
      a.each do |e|
        v <<= 8
        v += e
      end
      v
    end

    def dump_packet packet
      a =
        packet.map{|e|
          e.to_s(16).rjust(2, '0')
        }
      "[#{a.join(', ')}]"
    end

  end

end
end
end
