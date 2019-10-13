#
# Copyright (c) 2018 ITO SOFT DESIGN Inc.
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

dir = Dir.pwd
$:.unshift dir unless $:.include? dir

require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'plugin_trigger_state'

module PlcPlugins

  #def self.included(klass)
  #  load_plugins
  #end

  private

    def plugins
      @plugins ||= []
    end

    def load_plugins
      return unless plugins.empty?
      seen = {}

      Dir.glob("plugins/*_plugin.rb").each do |plugin_path|
        name = File.basename plugin_path, "_plugin.rb"
        next if seen[name]
        seen[name] = true

        require plugin_path.gsub(/\.rb$/, "")
        plugins << name
      end
      init_plugins
    end

    def init_plugins
      send_message_plugins "init", self
    end

    def exec_plugins
      send_message_plugins "exec", self
    end

    def send_message_plugins method, arg
      plugins.each do |plugin|
        msg = "plugin_#{plugin}_#{method}"
        unless arg
          send msg if Object.respond_to?(msg, true)
        else
          send msg, arg if Object.respond_to?(msg, true)
        end
      end
    end

end

module LadderDrive
module Emulator

class Plugin

  attr_reader :plc
  attr_reader :config

  class << self

    def devices_with_plc_from_str plc, dev_str
      dev_str.split(",").map{|e| e.split("-")}.map do |devs|
        devs = devs.map{|d| plc.device_by_name d.strip}
        d1 = devs.first
        d2 = devs.last
        [d2.number - d1.number + 1, 1].max.times.inject([]){|a, i| a << d1; d1 += 1; a}
      end.flatten
    end

    def device_names_with_plc_from_str plc, dev_str
      devices_with_plc_from_str.map{|d| d.name}
    end

  end

  def devices_with_plc_from_str plc, dev_str
    self.class.devices_with_plc_from_str plc, dev_str
  end

  def device_names_with_plc_from_str plc, dev_str
    self.class.device_names_with_plc_from_str plc, dev_str
  end

  def initialize plc
    @config = load_config
    @plc = plc
    @device_states = {}
    @interval_triggered_times = {}
  end

  def name
    @name ||= self.class.name.split(":").last.underscore.scan(/(.*)_plugin$/).first.first
  end

  def disabled?
    config.empty? || config[:disable]
  end

  def run_cycle plc
    return false unless self.plc == plc
  end

  def triggered? trigger_config
    s = @device_states[trigger_config.object_id] ||= PluginTriggerState.new(plc, trigger_config)
    s.triggered?
  end

  private

    def load_config
      h = {}
      path = File.join("config", "plugins", "#{name}.yml")
      if File.exist?(path)
        erb = ERB.new File.read(path)
        h = YAML.load(erb.result(binding))
        h = JSON.parse(h.to_json, symbolize_names: true)
      end
      h
    end


end


end
end
