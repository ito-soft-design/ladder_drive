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
  return if @plugin_ifttt_config[:disable]

  @plugin_ifttt_values = {}
  @plugin_ifttt_times = {}
  @plugin_ifttt_worker_queue = Queue.new
  Thread.start {
    plugin_ifttt_worker_loop
  }
end

def plugin_ifttt_exec plc
  return if @plugin_ifttt_config[:disable]
  return unless @plugin_ifttt_config[:web_hook_key]

  @plugin_ifttt_config[:events].each do |event|
    begin
      triggered = false
      case event[:trigger][:type]
      when "interval"
        now = Time.now
        t = @plugin_ifttt_times[event.object_id] || now
        triggered = t <= now
        if triggered
          t += event[:trigger][:interval] || 300
          @plugin_ifttt_times[event.object_id] = t
        end
      else
        d = plc.device_by_name event[:trigger][:device]
        v = d.send event[:trigger][:value_type], event[:trigger][:text_length] || 8
        unless @plugin_ifttt_values[event.object_id] == v
          @plugin_ifttt_values[event.object_id] = v
          case event[:trigger][:type]
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

      @plugin_ifttt_worker_queue.push event:event[:name], payload:event[:params].dup || {}, value:v
    rescue => e
      p e
    end
  end if @plugin_ifttt_config[:events]
end

def plugin_ifttt_worker_loop
  while arg = @plugin_ifttt_worker_queue.pop
    begin
      uri = URI.parse("https://maker.ifttt.com/trigger/#{arg[:event]}/with/key/#{@plugin_ifttt_config[:web_hook_key]}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Post.new(uri.path)
      payload = arg[:payload]
      payload.keys.each do |key|
        payload[key] = arg[:value] if payload[key] == "__value__"
      end
      req.set_form_data(payload)

      http.request(req)
    rescue => e
      # TODO: Resend if it fails.
      p e
    end
  end
end
