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

  class CModeProtocol < Protocol

    attr_accessor :baudrate
    attr_accessor :unit_no

    DELIMITER = "\r"
    TERMINATOR = "*\r"
    TIMEOUT = 1.0

    def initialize options={}
      super
      @port = options[:port] || `ls /dev/tty.usb*`.split("\n").map{|l| l.chomp}.first
      @baudrate = 38400
      @unit_no = 0
      @comm = nil
      #prepare_device_map
    end

    def open
      open!
    rescue
      nil
    end

    def open!
      return false unless @port
      begin
        # port, baudrate, bits, stop bits, parity(0:none, 1:even, 2:odd)
        @comm ||= SerialPort.new(@port, @baudrate, 7, 2, 1).tap do |s|
          s.read_timeout = (TIMEOUT * 1000.0).to_i
        end
      rescue => e
        p e
        nil
      end
    end

    def close
      @comm.close if @comm
      @comm = nil
    end

    def unit_no= no
      @unit_no = [[no, 0].max, 31].min
    end

    def get_bit_from_device device
      device = device_by_name device
      get_bits_from_device(1, device).first
    end

    def get_bits_from_device count, device
      device = device_by_name device

      # convert to the channel device
      from = device.channel_device
      to = (device + count).channel_device
      c = [to - from, 1].max

      # get value as words
      words = get_words_from_device(c, device)

      # convert to bit devices
      index = device.bit
      bits = []
      count.times do
        i = index / 16
        b = index % 16
        f = 1 << b
        bits << ((words[i] & f) == f)
        index += 1
      end
      bits
    end

    def get_word_from_device device
      device = device_by_name device
      get_words_from_device(1, device).first
    end

    def get_words_from_device(count, device)
      device = device_by_name(device).channel_device

      # make read packet
      packet = read_packet_with device
      packet << "#{device.channel.to_s.rjust(4, '0')}#{count.to_s.rjust(4, '0')}"
      packet << fcs_for(packet).to_s(16).upcase.rjust(2, "0")
      packet << TERMINATOR
      @logger.debug("> #{dump_packet packet}")

      # send command
      open
      send packet

      # receive response
      words = []
      terminated = false
      loop do
        res = receive
        data = ""
        if res
          ec = error_code(res)
          raise "Error response: #{ec.to_i(16).rjust(2, '0')}" unless ec == 0
          if res[-2,2] == TERMINATOR
            fcs = fcs_for(res[0..-5])
            raise "Not matched FCS expected #{fcs.to_s(16).rjust(2,'0')}" unless fcs == res[-4,2].to_i(16)
            data = res[7..-5]
            terminated = true
          else res[-1,1] == DELIMITER
            fcs = fcs_for(res[0..-4])
            raise "Not matched FCS expected #{fcs.to_s(16).rjust(2,'0')}" unless fcs == res[-3,2].to_i(16)
            data = res[7..-4]
          end
          len = data.length
          index = 0
          while index < len
            words << data[index,4].to_i(16)
            index += 4
          end
          return words if terminated
        else
          break
        end
      end
      []
    end

    private

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

    def send packet
      @comm.write(packet)
      @comm.flush
    end

    def receive
      res = ""
      begin
        Timeout.timeout(TIMEOUT) do
          res = @comm.gets DELIMITER
=begin
          loop do
            res << @comm.getc# '\r' #gets
            break if res[-1] == '\r'
          end
=end
        end
#        res
      rescue Timeout::Error
        puts "*** ERROR: TIME OUT : #{res} ***"
      end
      @logger.debug("< #{dump_packet res}")
      res
    end


    def read_packet_with device
      packet = "@#{unit_no.to_s.rjust(2, '0')}R"
      case device.suffix
      when "HR"
        packet << "H"
      when "AL"
        packet << "L"
      when "DM", "D"
        packet << "D"
      when "AR"
        packet << "J"
      when "EM", "E"
        packet << "E"
      else
        packet << "R"
      end
    end

    def fcs_for packet
      fcs = packet.bytes.inject(0) do |a, b|
        a = a ^ b
      end
      fcs = fcs & 0xff
      fcs
    end

    def error_code packet
      packet[1 + 2 + 2, 2].to_i(16)
    end

    def dump_packet packet
      packet.inspect
    end

  end

end
end
end
