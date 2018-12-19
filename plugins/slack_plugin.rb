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
Puts your configuration to config/plugins/slack.yml

device_comments:
  - M0: エラー0
  - M1: エラー1
  - M2: エラー2
  - M10: エラー10

events:
  - webhook_url: your_web_hook_url
    trigger:
      type: raise_and_fall
      value_type: bool
    format:
      raise: __device_comment__ が発生しました。
      fall: __device_comment__ が解除になりました。
    devices: M0-M2,M10
DOC

require 'net/https'

def plugin_slack_init plc
  @plugin_slack_config = load_plugin_config 'slack'

  @plugin_slack_values = {}
  @plugin_slack_times = {}
  @plugin_slack_worker_queue = Queue.new

  # collect comments
  @plugin_slack_comments = {}
  @plugin_slack_config[:device_comments].each do |k, v|
    d = plc.device_by_name(k)
    @plugin_slack_comments[d.name] = v if d
  end if @plugin_slack_config[:device_comments]

  Thread.start {
    plugin_slack_worker_loop
  }
end

def plugin_slack_exec plc
  return if @plugin_slack_config.empty? || @plugin_slack_config[:disable]

  @plugin_slack_config[:events].each do |event|
    next unless event[:devices]
    next unless event[:webhook_url]
    begin

      # gether values
      devices = event[:devices].split(",").map{|e| e.split("-")}.map do |devs|
        devs = devs.map{|d| plc.device_by_name d.strip}
        d1 = devs.first
        d2 = devs.last
        d = d1
        [d2.number - d1.number + 1, 1].max.times.inject([]){|a, i| a << d1; d1 += 1; a}
      end.flatten

      interval_triggered = false
      now = Time.now
      devices.each do |device|
        triggered = false
        v = nil
        case event[:trigger][:type]
        when "interval"
          t = @plugin_slack_times[event.object_id] || now
          triggered = t <= now
          if triggered
            interval_triggered = true
            t += event[:trigger][:interval] || 300
            @plugin_slack_times[event.object_id] = t
          end
          v = device.send event[:value_type], event[:trigger][:text_length] || 8
        else
          v = device.send event[:value_type], event[:text_length] || 8
          unless @plugin_slack_values[device.name] == v
            @plugin_slack_values[device.name] = v
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

        next unless triggered || interval_triggered

        @plugin_slack_worker_queue.push event:event,
                                        device_name:device.name,
                                        value:v,
                                        time: now
      end
    rescue => e
      p e
    end
  end if @plugin_slack_config[:events]
end

def plugin_slack_worker_loop
  while arg = @plugin_slack_worker_queue.pop
    begin
      event = arg[:event]
      uri = URI.parse(event[:webhook_url])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Post.new(uri.path)
      req["Content-Type"] = "application/json"

      format = event[:format] || "__comment__ occured at __time__"
      format = arg[:value] ? format[:raise] : format[:fall] unless format.is_a? String

      device_name = arg[:device_name]
      comment = @plugin_slack_comments[device_name] || device_name
      value = arg[:value].to_s
      time = arg[:time].iso8601

      payload = {text:format.gsub(/__device_comment__/, comment).gsub(/__value__/, value).gsub(/__time__/, time).gsub(/__device_name__/, device_name)
                }
      req.body = payload.to_json

      http.request(req)
    rescue => e
      # TODO: Resend if it fails.
      p e
    end
  end
end
