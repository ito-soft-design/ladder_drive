require 'active_support/core_ext/string/inflections'
require "escalator/protocol/protocol"
require 'escalator/uploader'
require 'yaml'

include Escalator::Protocol::Mitsubishi

module Escalator


  class EscalatorConfig

    def self.default
      @config ||= begin
        config_path = File.join "config", "plc.yml"
        h = YAML.load(File.read(config_path)) if File.exist?(config_path)
        new h || {}
      end
    end

    def initialize options={}
      default = {input: "asm/main.asm", output: "build/main.hex"}
      @config = options.merge default
    end

    def protocol
      @protocol ||= begin
        plc_info = @config[:plc]
        p = eval("#{plc_info[:protocol].camelize}.new")
        p.host = plc_info[:host] if plc_info[:host]
        p.port = plc_info[:port] if plc_info[:port]
        p.log_level = plc_info[:log_level] if plc_info[:log_level]
        p
      rescue
        nil
      end
    end

    def uploader
      @uploader ||= begin
        u = Uploader.new
        u.protocol = self.protocol
        u.program_area = u.protocol.device_by_name(@config[:plc][:program_area]) if @config[:plc] && @config[:plc][:program_area]
        u
      end
    end

    def method_missing(name, *args)
      name = name.to_s unless name.is_a? String
      case name.to_s
      when /(.*)=$/
        @config[$1.to_sym] = args.first
      else
        @config[name.to_sym]
      end
    end

  end

end
