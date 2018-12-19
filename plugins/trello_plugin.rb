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
Puts your configuration to config/plugins/trello.yml

consummer_key: your_consumer_key
consumer_secret: your_consumer_secret
oauth_token: your_oauth_token

events:
  - trigger:
      device: D0
      type: changed
      value_type: text
      text_length: 8
    board_name: 工程モニター
    list_name: 工程1
    title: __value__
  - trigger:
      device: D10
      type: changed
      value_type: text
      text_length: 8
    board_name: 工程モニター
    list_name: 工程2
    title: __value__
DOC

require 'net/https'
require 'trello'

# @see https://qiita.com/tbpgr/items/60fc13aca8afd153e37b

=begin
Dotenv.load

b =  Trello::Board.all.find{|b| b.name == "工程モニター"}
pp b.lists.map{|l| {id:l.id, name:l.name, cards:l.cards.map{|c| {id:c.id, name:c.name}}}}
=end


def plugin_trello_init plc
  @plugin_trello_config = load_plugin_config 'trello'

  @plugin_trello_values = {}
  @plugin_trello_times = {}
  @plugin_trello_worker_queue = Queue.new

  @plugin_trello_configured = Trello.configure do |config|
    config.consumer_key = @plugin_trello_config[:consumer_key]
    config.consumer_secret = @plugin_trello_config[:consumer_secret]
    config.oauth_token = @plugin_trello_config[:oauth_token]
  end

  Thread.start {
    plugin_trello_worker_loop
  }
end

def plugin_trello_exec plc
  return if @plugin_trello_config.empty? || @plugin_trello_config[:disable]
#  return unless @plugin_trello_configured

  @plugin_trello_config[:events].each do |event|
    begin

      triggered = false
      now = Time.now
      device = nil

      case event[:trigger][:type]
      when "interval"
        t = @plugin_trello_times[event.object_id] || now
        triggered = t <= now
        if triggered
          interval_triggered = true
          t += event[:trigger][:interval] || 300
          @plugin_trello_times[event.object_id] = t
        end
      else
        device = plc.device_by_name event[:trigger][:device]
        v = device.send event[:trigger][:value_type], event[:trigger][:text_length] || 8
        unless @plugin_trello_values[device.name] == v
          @plugin_trello_values[device.name] = v
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

      @plugin_trello_worker_queue.push event:event, device_name:device.name, value:v, time: now

    rescue => e
      p e
    end
  end if @plugin_trello_config[:events]
end

def plugin_trello_worker_loop
  while arg = @plugin_trello_worker_queue.pop
    begin
      event = arg[:event]

      board =  Trello::Board.all.find{|b| b.name == event[:board_name]}
      next unless board

      card_name = event[:card_name].dup || ""
      card_name.gsub!(/__value__/, arg[:value] || "")
      next if (card_name || "").empty?

      list_name = event[:list_name]
      next unless list_name
      list = board.lists.find{|l| l.name == list_name}
      next unless list

      card = board.lists.map{|l| l.cards.map{|c| c}}.flatten.find{|c| c.name == card_name}
      if card
        card.move_to_list list
      else
        card = Trello::Card.create name:card_name, list_id:list.id
      end

    rescue => e
      # TODO: Resend if it fails.
      p e
    end
  end
end
