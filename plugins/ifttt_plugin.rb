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

module LadderDrive
module Emulator

class IftttPlugin < Plugin

  def initialize plc
    super #plc
    return if disabled?

    @values = {}
    @times = {}
    @worker_queue = Queue.new
    setup
  end

  def run_cycle plc
    return if disabled?
    config[:events].each do |event|
      begin
        next unless self.triggered?(event)

        v = trigger_state_for(event).value
        @worker_queue.push event:event[:name], payload:event[:params].dup || {}, value:v
      rescue => e
puts $!
puts $@
        p e
      end
    end if config[:events]
  end

  def disabled?
    return false unless super
    unless config[:web_hook_key]
      puts "ERROR: IftttPlugin requires web_hook_key."
      false
    else
      super
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
          uri = URI.parse("https://maker.ifttt.com/trigger/#{arg[:event]}/with/key/#{config[:web_hook_key]}")
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

end

end
end

def plugin_ifttt_init plc
  @ifttt_plugin = LadderDrive::Emulator::IftttPlugin.new plc
end

def plugin_ifttt_exec plc
  @ifttt_plugin.run_cycle plc
end
