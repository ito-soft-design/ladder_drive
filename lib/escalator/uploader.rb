# The MIT License (MIT)
#
# Copyright (c) 2016 ITO SOFT DESIGN Inc.
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

require "escalator/plc_define"
require "escalator/plc_device"

module Escalator

  class Uploader
    include ::Escalator::PlcDefine

    attr_accessor :protocol
    attr_accessor :source
    attr_accessor :data

    def initialize options={}
      @protocol = options[:protocol] if options[:protocol]
    end

    def upload
      # stop plc
      stop_plc
      clear_program
      write_program
      run_plc
    end

    def data
      @data ||= begin
        hex = IntelHex.load @source
        hex.codes
      end
    end

    def word_data
      data.each_slice(2).map do |pair|
        pair << 0 if pair.size == 1
        pair.pack("c*").unpack("n*")
      end.flatten
    end

    private

      def stop_plc
        @protocol.set_word_to_device ESC_STATUS_TO_PLC_STOP_PLC_FLAG, EscDevice.status_to_plc_device
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device EscDevice.status_from_plc_device
          break if (v & ESC_STATUS_TO_PLC_STOP_PLC_FLAG) != 0
          sleep 0.1
        end
      end

      def clear_program
        @protocol.set_word_to_device ESC_STATUS_TO_PLC_STOP_PLC_FLAG | ESC_STATUS_TO_PLC_CLEAR_PROGRAM, EscDevice.status_to_plc_device
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device EscDevice.status_from_plc_device
          break if (v & ESC_STATUS_TO_PLC_CLEAR_PROGRAM) != 0
          sleep 0.1
        end
        @protocol.set_word_to_device ESC_STATUS_TO_PLC_STOP_PLC_FLAG, EscDevice.status_to_plc_device
      end

      def run_plc
        @protocol.set_word_to_device 0, EscDevice.status_to_plc_device
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device EscDevice.status_from_plc_device
          break if (v & ESC_STATUS_FROM_PLC_CYCLE_RUN) != 0
          sleep 0.1
        end
      end

      def write_program
        word_data.each_slice(2*1024) do |chunk|
          @protocol.set_words_to_device chunk, EscDevice.program_area_device
        end
      end

  end


end
