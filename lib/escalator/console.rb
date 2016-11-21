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

      loop do
        print "> "
        line = gets
        case line.chomp
        when /^\s*exit\s*$/, /^\s*quit\s*$/, /^\s*q\s*$/
          break
        when /^r\s+(\w+)(\s+(\d+))?/
          d = protocol.device_by_name $1
          c = $2 ? $2.to_i : 1
          values = protocol.get_from_devices d, c
          puts values.join(" ")
        when /^w\s+(\w+)/
          d = protocol.device_by_name $1
          v = $'.scan(/\d+/).map{|e| e.to_i}
          protocol.set_to_devices d, v
        when /^E\s+/
          puts protocol.execute(line)
        end
      end
    end

    private

      def protocol
        target.protocol
      end

  end

end
