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

require 'active_support/core_ext/string/inflections'
require 'yaml'
require 'json'
require 'protocol/protocol'

include LadderDrive::Protocol::Mitsubishi
include LadderDrive::Protocol::Keyence
include LadderDrive::Protocol::Emulator

module LadderDrive

  class LadderDriveConfigTarget

    class << self

      def finalize
        proc {
          EmuPlcServer.terminate
          RaspberrypiPlcServer.terminate
        }
      end

    end

    def initialize options={}
      @target_info = options
      ObjectSpace.define_finalizer(self, self.class.finalize)
    end

    def protocol
      @protocol ||= begin
        p = eval("#{@target_info[:protocol].camelize}.new")
        p.host = @target_info[:host] if @target_info[:host]
        p.port = @target_info[:port] if @target_info[:port]
        p.log_level = @target_info[:log_level] if @target_info[:log_level]
        p
      rescue
        nil
      end
    end

    def uploader
      @uploader ||= begin
        u = Uploader.new
        u.protocol = self.protocol
        u
      end
    end

    def method_missing(name, *args)
      name = name.to_s unless name.is_a? String
      case name.to_s
      when /(.*)=$/
        @target_info[$1.to_sym] = args.first
      else
        @target_info[name.to_sym]
      end
    end

    def run
      case self.name
      when :emulator
        Plc::Emulator::EmuPlcServer.launch
      when :raspberrypi
        Plc::Raspberrypi::RaspberrypiPlcServer.launch
      else
        # DO NOTHIN
        # Actual device is running independently.
      end
    end

  end

end
