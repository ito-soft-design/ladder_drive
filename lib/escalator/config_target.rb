
require 'active_support/core_ext/string/inflections'
require 'yaml'
require 'json'
require 'protocol/protocol'

include Escalator::Protocol::Mitsubishi
include Escalator::Protocol::Keyence
include Escalator::Protocol::Emulator

module Escalator

  class EscalatorConfigTarget

    class << self

      def finalize
        proc {
          EmuPlcServer.terminate
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
      else
        # DO NOTHIN
        # Actual device is running independently.
      end
    end

  end

end
