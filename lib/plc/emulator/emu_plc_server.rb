require 'webrick'
require 'fileutils'
require 'escalator/plc_device'

include FileUtils

module Plc
module Emulator

  class EmuPlcServer < WEBrick::GenericServer

    class << self

      def pid_dir
        @pid_dir ||= File.expand_path(File.join(Dir.pwd, "tmp", "pids"))
      end

      def pid_file_path
        @pid_path ||= File.join(pid_dir, "emu_plc.pid")
      end

      def launch
        @server ||= begin
          mkdir_p pid_dir
          server = new( Port:5555,
                        ServerType: WEBrick::Daemon,
                        StartCallback: Proc.new {
                          File.write(pid_file_path, $$)
                        }
          )
          fork do
            trap(:INT) { server.shutdown }
            server.start
          end
          server
        end
      end

      def finalize
        proc { terminate }
      end

      def terminate
        `kill #{File.read(pid_file_path)}` if File.exist? pid_file_path
      end

    end

    def initialize config = {}, default = WEBrick::Config::General
      super
      @plc = EmuPlc.new
      ObjectSpace.define_finalizer(self, self.class.finalize)
    end

    def run socket
      @plc.run
      loop do
        begin
          line = socket.gets
          line.chomp!
          a = line.split(/\s/)
          case a.first
          when /^ST/i
            d = @plc.device_by_name a[1]
            d.bool = true
            socket.puts "OK\r"
          when /^RS/i
            d = @plc.device_by_name a[1]
            d.bool = false
            socket.puts "OK\r"
          when /^RDS/i
            d = @plc.device_by_name a[1]
            c = a[2].to_i
            r = c.times.map do
              v = 0
              if d.bit_device?
                v = d.bool ? 1 : 0
              else
                v = d.word
              end
              d += 1
              v
            end
            socket.puts r.map{|e| e.to_s}.join(" ") + "\r"
          when /^WRS/i
            d = @plc.device_by_name a[1]
            c = a[2].to_i
            a[3, c].each do |v|
              v = v.to_i
              if d.bit_device?
                d.bool = v == 0 ? false : true
              else
                d.word = v
              end
            end
            socket.puts "OK\r"
          else
            raise "Unknown command #{a.first}"
          end
        rescue => e
          socket.puts "E0 #{e}\r"
        end
      end
    end


  end

end
end
