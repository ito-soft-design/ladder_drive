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


module LadderDrive
module Emulator

class SlackPlugin < Plugin

  def initialize plc
    super #plc
    return if disabled?

    @values = {}
    @times = {}
    @worker_queue = Queue.new

    # collect comments
    @comments = {}
    config[:device_comments].each do |k, v|
      d = plc.device_by_name(k)
      @comments[d.name] = v if d
    end if config[:device_comments]
    setup
  end

  def run_cycle plc
    return if disabled?
    return unless config[:events]

    config[:events].each do |event|
      next unless event[:devices]
      next unless event[:webhook_url]
      begin

        # gether values
        devices = event[:devices].split(",").map{|e| e.split("-")}.map do |devs|
          devs = devs.map{|d| plc.device_by_name d.strip}
          d1 = devs.first
          d2 = devs.last
          [d2.number - d1.number + 1, 1].max.times.inject([]){|a, i| a << d1; d1 += 1; a}
        end.flatten

        interval_triggered = false
        now = Time.now
        devices.each do |device|
          triggered = false
          v = nil
          case event[:trigger][:type]
          when "interval"
            t = @times[event.object_id] || now
            triggered = t <= now
            if triggered
              interval_triggered = true
              t += event[:trigger][:interval] || 300
              @times[event.object_id] = t
            end
            v = device.send event[:value_type] || :device, event[:trigger][:text_length] || 8
          else
            v = device.send event[:value_type] || :value, event[:text_length] || 8
            unless @values[device.name] == v
              @values[device.name] = v
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

          @worker_queue.push event:event,
                                          device_name:device.name,
                                          value:v,
                                          time: now
        end
      rescue => e
        p e
puts $!
puts $@
      end
    end
  end

  private

    def setup
      Thread.start {
        thread_proc
      }
    end

    def thread_proc
      while arg = @worker_queue.pop
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
          comment = @comments[device_name] || device_name
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

end

end
end


def plugin_slack_init plc
  @slack_plugin = LadderDrive::Emulator::SlackPlugin.new plc
end

def plugin_slack_exec plc
  @slack_plugin.run_cycle plc
end
