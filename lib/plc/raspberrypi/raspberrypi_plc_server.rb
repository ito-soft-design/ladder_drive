#
# Copyright (c) 2017 ITO SOFT DESIGN Inc.
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

require 'socket'
require 'ladder_drive/plc_device'

module Plc
module Raspberrypi

  class RaspberrypiPlcServer

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
      @plc = RaspberrypiPlc.new
    end

    def run
      puts "launching respberrypi plc ... "
      @plc.run
      puts "done launching"

      Thread.new do
        server = TCPServer.open @port
        loop do
          Thread.start(server.accept) do |socket|
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
end
