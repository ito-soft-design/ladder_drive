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
require 'yaml'
require 'json'
require 'protocol/protocol'

include LadderDrive::Protocol::Mitsubishi
include LadderDrive::Protocol::Keyence
include LadderDrive::Protocol::Emulator

module LadderDrive

  class LadderDriveConfig

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
      }
      emulator_default = {
        host: "localhost",
        port: 5555,
        protocol: "emu_protocol",
      }

      @config = default.merge options
      @config[:plc] ||= {}
      @config[:plc][:emulator] = @config[:plc][:emulator] ? emulator_default.merge(@config[:plc][:emulator]) : emulator_default

      @config[:default] ||= {}

      @targets = {}
    end

    def [] key
      @config[key]
    end

    def target name=nil
      name ||= (@config[:default][:target] || :emulator)
      name = name.to_sym if name.is_a? String
      target = @targets[name]
      unless target
        h = @config[:plc][name]
        unless h.nil? || h.empty?
          h = {name:name}.merge h
          target = LadderDriveConfigTarget.new h
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

end
