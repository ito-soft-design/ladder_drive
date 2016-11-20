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
          r = @plc.execute_console_commands socket.gets
          socket.puts r
        rescue => e
          socket.puts "E0 #{e}\r"
        end
      end
    end


  end

end
end
