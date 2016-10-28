require 'socket'
require 'logger'
require 'timeout'

module Protocol

  module Mitsubishi

    class McProtocol < Protocol

      def initialize options={}
        super
        @host = options[:host] || "192.168.0.1"
        @port = options[:port] || 5010
      end

      def open
        @socket ||= TCPSocket.open(@host, @port)
      end

      def close
        @socket.close if @socket
        @socket = nil
      end

      def get_bool_value(device)
        packet = get_packet body_for_get_bit_deivce(device)
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        res = res[11]
        res = (res >> 4) != 0
        @logger.debug("get #{device.name} => #{res}")
        res
      end

      def set_bool_value(device, value)
        packet = get_packet body_for_set_bit_device(device, value)
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        @logger.debug("set #{value} => #{device.name}")
      end

      def get_word_value(device)
        packet = get_packet body_for_get_word_deivce(device)
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        res = res[11] + (res[12] << 8)
        @logger.debug("get #{device.name} => #{res}")
        res
      end

      def set_word_value(device, value)
        packet = get_packet body_for_set_word_device(device, value)
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        @logger.debug("set #{value} => #{device.name}")
      end

      def bit_device? device
        return name_elements_for_bit_device device
      rescue
        false
      end

      def word_device? device
        return name_elements_for_word_device device
      rescue
        false
      end



      def receive
        res = []
        len = 0
        begin
          Timeout.timeout(0.1) do
            while  true
              c = @socket.read(1)
              next if c.nil? || c == ""

              res << c.bytes.first
              len = res[7] + res[8] << 8 if res.length >= 9
              break if (len + 9 == res.length)
            end
          end
        rescue Timeout::Error
        end
        @logger.debug("< #{res}")
        res
      end

    private

      def get_packet body
        header = [0x50, 0x00,  0x00,  0xff,  0xff, 0x03,  0x00,  0x00, 0x00,  0x10,  0x00]
        header[7..8] = data_for_short(body.length + 2)
        header + body
      end

      def body_for_get_bit_deivce device, count = 1
        body_for_get_word_deivce device, count, false
      end

      def body_for_get_word_deivce device, count = 1, word = true
        body = [0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
        body[2] = 1 unless word
        body[4..7] = data_for_device(device)
        body[8..9] = data_for_short count
        body
      end


      def body_for_set_bit_device device, value
        body_for_set_word_device device, value, false
      end

      def body_for_set_word_device device, value, word = true
        body = [0x01, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
        d = device
        values = value.is_a?(Array) ? value : [value]
        unless word
          body[2] = 1
          values.each do |v|
            body << (v ? 0x10 : 0x00)
            d = d.next_device
          end
        else
          values.each do |v|
            body += data_for_short v
            d = d.next_device
          end
        end
        body[4..7] = data_for_device(device)
        body[8..9] = data_for_short values.size
        body
      end

      def data_for_device device
        a = data_for_int device.number
        a[3] = device.suffix_code
        a
      end

      def data_for_short value
        a = []
        a << (value & 0xff); value >>= 8
        a << (value & 0xff)
        a
      end

      def data_for_int value
        a = []
        a << (value & 0xff); value >>= 8
        a << (value & 0xff); value >>= 8
        a << (value & 0xff); value >>= 8
        a << (value & 0xff)
        a
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

    end

  end

end
