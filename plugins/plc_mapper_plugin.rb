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
Puts your configuration to config/plugins/plc_mapper.yml

plcs:
  - description: Machine A-123
    protocol: mc_protocol
    host: 192.168.0.1
    port: 5010
    interval: 60
    mapping:
      read:
        - plc: M1000-M1099
          ld: M0
        - plc: D1000-D1099
          ld: D0
      write:
        - plc: M100-M199
          ld: M1100
        - plc: D100-D199
          ld: D1100
DOC

module LadderDrive
module Emulator

class PlcMapperPlugin < Plugin

  attr_reader :lock
  attr_reader :values_for_reading
  attr_reader :values_for_writing

  def initialize plc
    super #plc
    @lock = Mutex.new
    @values_for_reading = {}
    @values_for_writing = {}
    setup unless config[:disable]
  end

  def run_cycle plc
    return false unless super
    @lock.synchronize {
      # set values from plcs to ladder drive.
      values_for_reading.each do |d, v|
        plc.device_by_name(d).value = v
      end
      values_for_reading.clear

      # set values from ladder drive to values_for_writing.
      # then set it to plc at #sync_with_plc
      values_for_writing.each do |d, v|
        values_for_writing[d] = plc.device_by_name(d).value
      end
    }
  end

  private

    def setup
      config[:plcs].each do |plc_config|
        Thread.start(plc_config) {|plc_config|
          mapping_thread_proc plc_config
        }
      end
    end

    def protocol_with_config config
      begin
        eval("#{config[:protocol].camelize}.new").tap do |protocol|
          protocol.host = config[:host] if config[:host]
          protocol.port = config[:port] if config[:port]
        end
      rescue
        nil
      end
    end

    def mapping_devices protocol, mappings
      mappings.map do |h|
        a = []
        h.each do |k, v|
          devs = v.split("-").map{|d|
            protocol.device_by_name d.strip
          }
          d1 = devs.first
          d2 = devs.last
          a << k
          a << [d1, [d2.number - d1.number + 1, 1].max]
        end
        Hash[*a]
      end
    end

    def mapping_thread_proc config
      protocol = protocol_with_config config

      read_mappings = mapping_devices protocol, config[:mapping][:read]
      write_mappings = mapping_devices protocol, config[:mapping][:write]

      interval = config[:interval]
      next_time = begin
        t = Time.now.to_f
        t = t - t % interval
        Time.at t
      end

      alerted = false
      loop do
        begin
          now = Time.now
          if next_time <= now
            sync_with_plc protocol, read_mappings, write_mappings
            next_time += interval
          end
          sleep next_time - Time.now
          alerted = false
        rescue => e
          puts "#{config[:description]} is not reachable." unless alerted
          alerted = true
        end
      end
    end

    def sync_with_plc protocol, read_mappings, write_mappings
      # set values from plc to values_for_reading.
      read_mappings.each do |mapping|
        src_d, c = mapping[:plc]
        values = protocol[src_d.name, c]
        dst_d = plc.device_by_name mapping[:ld].first.name
        lock.synchronize {
          values.each do |v|
            values_for_reading[dst_d.name] = v
            dst_d = dst_d.next_device
          end
        }
      end

      # set values form ladder drive (values_for_writing) to plc
      # values_for_writing was set at run_cycle
      # but for the first time, it's not known what device it should take.
      # after running below, devices for need is listed to values_for_writing.
      write_mappings.each do |mapping|
        dst_d, c = mapping[:plc]
        src_d = plc.device_by_name mapping[:ld].first.name
        values = []
        lock.synchronize {
          # It may not get the value for the first time, set zero instead of it.
          values_for_writing[src_d.name] ||= 0
          values << values_for_writing[src_d.name]
          src_d = src_d.next_device
        }
        protocol[dst_d.name, c] = values
      end
    end

end

end
end


def plugin_plc_mapper_init plc
  @plugin_plc_mapper = LadderDrive::Emulator::PlcMapperPlugin.new plc
end

def plugin_plc_mapper_exec plc
  @plugin_plc_mapper.run_cycle plc
end
