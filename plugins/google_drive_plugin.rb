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
Puts your configuration to config/plugins/google_drive.yml

client_id: your_auth_2_0_client_id
client_secret: your_client_secret
refresh_token: your_refresh_token

loggings:
  - name: temperature
    trigger:
      device: M0
      type: raise_and_fall
      value_type: bool
    columns: D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,D20,M0
    devices:
      - device: D0-D9
        type: value
      - device: D20
        type: value
      - device: M0
        type: bool
    spread_sheet:
      spread_sheet_key: 1LGiGzMUVj_NcdWRpzv9ivjtNKSWQa_0RXtK_4bch3bY
      sheet_no: 0
  - name: voltages
    trigger:
      type: interval
      interval: 30.0
    columns: D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,D20,M0
    devices:
      - device: D0-D9
        type: value
      - device: D20
        type: value
      - device: M0
        type: bool
    spread_sheet:
      spread_sheet_key: 1LGiGzMUVj_NcdWRpzv9ivjtNKSWQa_0RXtK_4bch3bY
      sheet_name: Sheet2
DOC

require 'net/https'
require 'google_drive'

def plugin_google_drive_init plc
  @plugin_google_drive_config = load_plugin_config 'google_drive'
  return if @plugin_google_drive_config.empty? || @plugin_google_drive_config[:disable]

  @plugin_google_drive_values = {}
  @plugin_google_drive_times = {}
  @plugin_google_drive_worker_queue = Queue.new

  begin
    # generate config file for google drive session
    tmp_dir = File.expand_path "tmp"
    session_path = File.join(tmp_dir, "google_drive_session.json")
    unless File.exist? session_path
      mkdir_p tmp_dir
      conf =
        [:client_id, :client_secret, :refresh_token].inject({}) do |h, key|
          v = @plugin_google_drive_config[key]
          h[key] = v if v
          h
        end
      File.write session_path, JSON.generate(conf)
    end

    # create google drive session
    @plugin_google_drive_session = GoogleDrive::Session.from_config(session_path)

    # start worker thread
    Thread.start {
      plugin_google_drive_worker_loop
    }
  rescue => e
    p e
    @plugin_google_drive_session = nil
  end
end

def plugin_google_drive_exec plc
  return if @plugin_google_drive_config.empty? || @plugin_google_drive_config[:disable]
  return unless @plugin_google_drive_session

  @plugin_google_drive_config[:loggings].each do |logging|
    begin
      # check triggered or not
      triggered = false
      case logging[:trigger][:type]
      when "interval"
        now = Time.now
        t = @plugin_google_drive_times[logging.object_id] || now
        triggered = t <= now
        if triggered
          t += logging[:trigger][:interval] || 300
          @plugin_google_drive_times[logging.object_id] = t
        end
      else
        d = plc.device_by_name logging[:trigger][:device]
        v = d.send logging[:trigger][:value_type], logging[:trigger][:text_length] || 8
        unless @plugin_google_drive_values[logging.object_id] == v
          @plugin_google_drive_values[logging.object_id] = v
          case logging[:trigger][:type]
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

      # gether values
      values = logging[:devices].map do |config|
        d1, d2 = config[:device].split("-").map{|d| plc.device_by_name d}
        devices = [d1]
        if d2
          d = d1 + 1
          devices += [d2.number - d1.number, 0].max.times.inject([]){|a, i| a << d; d += 1; a}
        end
        devices.map{|d| d.send config[:type], config[:length] || 8}
      end.flatten
      @plugin_google_drive_worker_queue.push logging:logging, values:values, time:Time.now
    rescue => e
      p e
    end
  end if @plugin_google_drive_config[:loggings]
end

def plugin_google_drive_worker_loop
  while arg = @plugin_google_drive_worker_queue.pop
    begin
      logging = arg[:logging]
      spread_sheet = @plugin_google_drive_session.spreadsheet_by_key(logging[:spread_sheet][:spread_sheet_key])

      # get worksheet
      worksheet = begin
        if logging[:spread_sheet][:sheet_name]
          spread_sheet.worksheet_by_title logging[:spread_sheet][:sheet_name]
        else
          spread_sheet.worksheets[logging[:spread_sheet][:sheet_no] || 0]
        end
      end

      # write columns if needs
      if worksheet.num_rows == 0
        worksheet[1, 1] = "Time"
        logging[:columns].split(",").each_with_index do |t, i|
          worksheet[1, i + 2] = t
        end
      end

      # write values
      r = worksheet.num_rows + 1
      worksheet[r, 1] = arg[:time]
      arg[:values].each_with_index do |v, i|
        worksheet[r, i + 2] = v
      end if arg[:values]
      worksheet.save
    rescue => e
      # TODO: Resend if it fails.
      p e
    end
  end
end
