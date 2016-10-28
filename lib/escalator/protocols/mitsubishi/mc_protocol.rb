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

      def get_bit_from_device device
        get_bits_from_device(1, device).first
      end

      def get_bits_from_device count, device
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
        packet = make_packet(body_for_set_bits_to_device(bits, device))
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        @logger.debug("set #{bits} to:#{device.name}")
      end
      alias :set_bit_to_device :set_bits_to_device

      def get_word_from_device device
        get_words_from_device(1, device).first
      end

      def get_words_from_device(count, device)
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
        packet = make_packet(body_for_set_words_to_device(words, device))
        @logger.debug("> #{dump_packet packet}")
        open
        @socket.write(packet.pack("c*"))
        @socket.flush
        res = receive
        @logger.debug("set #{words} to: #{device.name}")
      end
      alias :set_word_to_device :set_words_to_device



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

    end

  end

end
