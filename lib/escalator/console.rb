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
        end
      end
    end

    private

      def protocol
        target.protocol
      end

  end

end
