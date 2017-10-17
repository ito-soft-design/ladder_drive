#
# Copyright (c) 2017 ITO SOFT DESIGN Inc.
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

require 'ladder_drive/plc_device'
require 'plc/emulator/emulator'
require 'pi_piper'

include LadderDrive
include PiPiper


module Plc
module Raspberrypi

  class RaspberrypiPlc < Plc::Emulator::EmuPlc

    def initialize config={}
      super
      setup_io
    end

    private

      def setup_io
        @available_pi_piper = false
        @io_dict = { inputs:[], outputs:[] }
        config[:io][:inputs].each do |dev, info|
          @io_dict[:inputs] << [device_by_name(dev), Pin.new(pin:info[:pin], direction: :in, pull:(info[:pull].to_sym || :off))]
        end
        config[:io][:outputs].each do |dev, info|
          @io_dict[:outputs] << [device_by_name(dev), Pin.new(pin:info[:pin], direction: :out)]
        end
        @available_pi_piper = true
      rescue LoadError
      end

      def sync_input
        if @available_pi_piper
          @io_dict[:inputs].each do |a|
            a.first.set_value a.last.on?, :in
          end
        end
        super
      end

      def sync_output
        super
        return unless @available_pi_piper

        @io_dict[:inputs].each do |a|
          a.last.on? ? a.first.on : a.first.off
        end
      end


  end

end
end
