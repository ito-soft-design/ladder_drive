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

require 'singleton'
require 'curses'

module Escalator

  attr_accessor :target

  class Console
    include Singleton

    def self.finalize
      proc {
        #Curses.close_screen
      }
    end

    def initialize
      #Curses.init_screen
      ObjectSpace.define_finalizer(self, self.class.finalize)
    end

    def run
      l = true
      trap(:INT) { puts "\n> " }

      display_title

      loop do
        begin
          print "> "
          line = STDIN.gets
          case line.chomp
          when /^\s*exit\s*$/, /^\s*quit\s*$/, /^\s*q\s*$/
            break
          when /^r\s+(\w+)(\s+(\d+))?/
            d = protocol.device_by_name EscDevice.new($1)
            c = $2 ? $2.to_i : 1
            values = protocol.get_from_devices d, c
            puts values.join(" ")
          when /^p\s+(\w+)(\s+(\d+))?/
            d = protocol.device_by_name EscDevice.new($1)
            t = $2 ? $2.to_f : 0.1
            protocol.set_to_devices d, 1
            sleep t
            protocol.set_to_devices d, 0
          when /^w\s+(\w+)/
            d = protocol.device_by_name EscDevice.new($1)
            v = $'.scan(/\d+/).map{|e| e.to_i}
            protocol.set_to_devices d, v
          when /^E\s+/
            puts protocol.execute(line)
          when /^help/, /^h/
            display_help
          end
        rescue => e
          puts "*** ERROR: #{e} ***"
        end
      end
    end

    private

      def protocol
        target.protocol
      end

      def display_title
        puts <<EOB

  Escalator is an abstract PLC.
  This is a console to communicate with PLC.

EOB
      end

      def display_help
        puts <<EOB
Commands:

  r: Read values from device.
     r device [count]
       e.g.) it reads values from M0 to M7.
             > r m0 8
  w: Write values to device.
     w device value1 value2 ...
       e.g.) it write values from D0 to D7.
             > w d0 1 2 3 4 5 6 7 8
       e.g.) it write values from M0 to M7.
             > w m0 0 0 0 1 1 0 1 1
  p: Pulse out on device. Default duration is 0.1 sec
     p device [duration]
       e.g.) it write 1 to m0, then write 0 after 0.5 sec.
             > w m0 0.5
  q: Quit this. You can use quit and exit instead of q.
  h: Show help. You can use help instead of h.

EOB
      end

  end

end
