require 'webrick'

module Plc
module Emulator

  class EmuPlcServer < WEBrick::GenericServer

    class << self

      def launch
        server = EmuPlc.new(:Port => 5555)
        trap(:INT) { server.shutdown }
        server.start
      end

    end

    def initialize config = {}, default = WEBrick::Config::General
      super
      @plc = EmuPlc.new
    end

    def run socket
      @plc.run
      loop do
        c = socket.gets
        puts c.chomp
      end
    end

  end

end
end
