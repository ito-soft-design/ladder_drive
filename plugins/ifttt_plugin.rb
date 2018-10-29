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

<<-DOC
Here is a sample configuration.
Puts your configuration to config/plugins/ifttt.yml

web_hook_key: your_web_hook_key
events:
  - name: event1
    trigger:
      device: M0
      type: raise_and_fall
      value_type: bool
    params:
      value1: error
      value2: unit1
  - name: event2
    trigger:
      device: D0
      value: word
      type: changed
    params:
      value1: temperature
      value2: 値2
      value3: 値3
  - name: event3
    trigger:
      device: D2
      value: dword
      type: interval
      time: 10.0
    params:
      value1: @value
      value2: 値2
      value3: 値3
DOC

require 'net/https'

def plugin_ifttt_init plc
  @plugin_ifttt_config = load_plugin_config 'ifttt'
p @plugin_ifttt_config
  @plugin_ifttt_values = {}
end

def plugin_ifttt_exec plc
  return unless @plugin_ifttt_config[:web_hook_key]

  @plugin_ifttt_config[:events].each do |event|
    begin
      d = plc.device_by_name event[:trigger][:device]
      v = d.send event[:trigger][:value_type]

      triggered = false
      case event[:trigger]
      when "interval"
      else
        unless @plugin_ifttt_values[d.name] == v
          @plugin_ifttt_values[d.name] = v
          case event[:trigger]
          when "raise"
            triggered = !!v
          when "fall"
            triggered = !v
          else
            triggered = true
          end
        end
      end

      next unless triggered

      uri = URI.parse("https://maker.ifttt.com/trigger/#{event[:name]}/with/key/#{@plugin_ifttt_config[:web_hook_key]}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Post.new(uri.path)
      payload = event[:params].dup || {}
      payload.keys.each do |key|
        payload[key] = v if payload[key] == "self"
      end
      req.set_form_data(payload)

      http.request(req)
    rescue => e
      p e
    end
  end if @plugin_ifttt_config[:events]
end
