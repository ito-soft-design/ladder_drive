require 'singleton'
require 'curses'

module Escalator


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
        when /exit/, /quit/
          break
        end
        puts line
      end
    end

  end

end
