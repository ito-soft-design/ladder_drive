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
module Keyence

  class KvProtocol < Protocol

    def initialize options={}
      super
      @host = options[:host] || "192.168.0.10"
      @port = options[:port] || 8501
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
      c = (count + 15) / 16
      words = get_words_from_device c, device
      values = []
      count.times do |i|
        index = i / 16
        bit = i % 16
        values << ((words[index] & (1 << bit)) != 0)
      end
      values
    end

    def set_bits_to_device bits, device
      device = device_by_name device
      bits = [bits] unless bits.is_a? Array
      @logger.debug("#{device.name}[#{bits.size}] <= #{bits}")
      bits.each do |v|
        cmd = "ST"
        case v
        when false, 0
          cmd = "RS"
        end
        packet = "#{cmd} #{device.name}\r\n"
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.puts(packet)
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
      device = local_device device
      packet = "RDS #{device.name}.H #{count}\r\n"
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.puts(packet)
      res = receive
      values = res.split(/\s+/).map{|v| v.to_i(16)}
      @logger.debug("#{device.name}[#{count}] => #{values}")
      values
    end

    def set_words_to_device words, device
      device = local_device device
      words = [words] unless words.is_a? Array
      packet = "WRS #{device.name}.H #{words.size} #{words.map{|w| w.to_s(16)}.join(" ")}\r\n"
      @logger.debug("> #{dump_packet packet}")
      open
      @socket.puts(packet)
      res = receive
      @logger.debug("#{device.name}[#{words.size}] <= #{words}")
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

    def available_bits_range suffix=nil
      case suffix
      when "TM"
        1..512
      when "TM"
        1..12
      when "T", "TC", "TS", "C", "CC", "CS"
        1..120
      when "CTH"
        1..2
      when "CTC"
        1..4
      when "AT"
        1..8
      else
        1..1000
      end
    end

    def available_words_range suffix=nil
      case suffix
      when "TM"
        1..256
      when "TM"
        1..12
      when "T", "TC", "TS", "C", "CC", "CS"
        1..120
        1..120
      when "CTH"
        1..2
      when "CTC"
        1..4
      when "AT"
        1..8
      else
        1..500
      end
    end


    private

      def device_class
        KvDevice
      end

      def prepare_device_map
        @conv_dev_dict ||= begin
          h = {}
          [
            ["X", "R0", 1024],
            ["Y", "R0", 1024],
            ["M", "MR0", 1024],
            ["C", "C0", 256],
            ["T", "T0", 256],
            ["L", "L0", 1024],
            ["SC", "MR1024", 1024],
            ["D", "DM0", 1024],
            ["H", "DM1024", 1024],
            ["SD", "DM2048", 1024],
            ["PRG", "DM3072", 1024]    # ..D4095
          ].each do |s,d,c|
            h[s] = [KvDevice.new(d), c]
          end
          h
        end
      end

      def local_device device
        return device if device.is_a? KvDevice
        d, c = @conv_dev_dict[device.suffix]
        return nil unless device.number < c
        ld = KvDevice.new(d.suffix, d.number + device.number)
        device_by_name ld.name
      end

  end

end
end
end
