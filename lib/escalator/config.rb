# The MIT License (MIT)
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
