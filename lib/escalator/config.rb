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
require 'json'

include Escalator::Protocol::Mitsubishi
include Escalator::Protocol::Keyence
include Escalator::Protocol::Emulator

module Escalator


  class EscalatorConfig

    class << self

      def default
        @config ||= begin
          load File.join("config", "plc.yml")
        end
      end

      def load path
        h = {}
        if File.exist?(path)
          h = YAML.load(File.read(path))
          h = JSON.parse(h.to_json, symbolize_names: true)
        end
        new h || {}
      end

    end

    def initialize options={}
      default = {
        input: "asm/main.asm",
        output: "build/main.hex",
        emulator: {
          host: "localhost",
          port: 5555,
          protocol: "emu_protocol",
        },
      }
      @config = default.merge options
      @targets = {}
    end

    def [] key
      @config[key]
    end

    def target name=nil
      name ||= :emulator
      name = name.to_sym if name.is_a? String
      target = @targets[name]
      unless target
        h = @config[name]
        unless h.nil? || h.empty?
          h = {name:name}.merge h
          target = EscalatorConfigTarget.new h
          @targets[name] = target
        end
      end
      target
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
        EmuPlcServer.launch
      else
        # DO NOTHIN
        # Actual device is running independently.
      end
    end

  end

end
