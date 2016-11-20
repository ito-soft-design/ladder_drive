require 'socket'
require 'escalator/plc_device'

module Plc
module Emulator

  class EmuPlcServer

    class << self

      def launch
        @server ||= begin
          server = new
          server.run
          server
        end
      end

    end

    def initialize config = {}
      @port = config[:port] || 5555
      @plc = EmuPlc.new
    end

    def run
      @plc.run
      Thread.new do
        server = TCPServer.open @port
        loop do
          socket = server.accept
          while line = socket.gets
            begin
              r = @plc.execute_console_commands line
              socket.puts r
            rescue => e
              socket.puts "E0 #{e}\r"
            end
          end
        end
      end
    end

  end

end
end
