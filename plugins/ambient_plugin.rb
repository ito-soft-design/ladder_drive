#
# Copyright (c) 2019 ITO SOFT DESIGN Inc.
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
Puts your configuration to config/plugins/ambient.yml

channels:
  - channel_id: 12345
    write_key: your_write_key
    trigger:
      device: M100
      type: raise_and_fall
      value_type: bool
    devices:
      d1:
        device: D30
        value_type: value
      d2:
        device: D17
        value_type: value
      d3:
        device: D11
        value_type: value
      d4:
        device: D22
        value_type: value
      d5:
        device: D25
        value_type: value
  - channel_id: 12345
    write_key: your_write_key
      type: interval
      interval: 60
    devices:
      d1:
        device: D30
        value_type: value
      d2:
        device: D17
        value_type: value
      d3:
        device: D11
        value_type: value
      d4:
        device: D22
        value_type: value
      d5:
        device: D25
        value_type: value
DOC

require 'ambient_iot'


module LadderDrive
module Emulator

class AmbientPlugin < Plugin

  def initialize plc
    super #plc
    return if disabled?

    @values = {}
    @worker_queue = Queue.new

    setup
  end

  def run_cycle plc
    return if disabled?
    return unless config[:channels]

    config[:channels].each do |channel|
      next unless channel[:channel_id]
      next unless channel[:write_key]
      begin
        next unless self.triggered?(channel)

        # gether values
        values = channel[:devices].inject({}) do |h, pair|
          d = plc.device_by_name pair.last[:device]
          v = d.send pair.last[:value_type], pair.last[:text_length] || 8
          h[pair.first] = v
          h
        end

        @worker_queue.push channel:channel, values:values
      rescue => e
        p e
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
      @uploaded_at = nil

      while arg = @worker_queue.pop
        begin
          now = Time.now
          # ignore a request if it's requested in a 5 sec from previous request.
          next unless @uploaded_at.nil? || (now - @uploaded_at >= 5)

          channel = arg[:channel]
          client = AmbientIot::Client.new channel[:channel_id], write_key:channel[:write_key]
          client << arg[:values]
          client.sync
          @uploaded_at = now
        rescue => e
          p e
        end
      end
    end

end

end
end


def plugin_ambient_init plc
  @ambient_plugin = LadderDrive::Emulator::AmbientPlugin.new plc
end

def plugin_ambient_exec plc
  @ambient_plugin.run_cycle plc
end
