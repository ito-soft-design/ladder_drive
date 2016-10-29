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

module Escalator

  class Uploader

    attr_accessor :protocol
    attr_accessor :program_area, :interaction_area
    attr_accessor :source
    attr_accessor :data

    def initialize options={}
      @protocol = options[:protocol] if options[:protocol]
      @program_area = options[:program_area] if options[:program_area]
      @interaction_area = options[:interaction_area] if options[:interaction_area]
    end

    STOP_PLC_FLAG         = 2     # bit 1
    CLEAR_PROGRAM_FLAG    = 4     # bit 2  require bit 1 on

    CYCLE_RUN_FLAG        = 2


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
        pair.pack("c*").unpack("n*")
      end.flatten
    end

    private

      def to_plc_status
        @to_plc_status ||= interaction_area
      end

      def from_plc_status
        @from_plc_status ||= interaction_area.next_device
      end


      def stop_plc
        @protocol.set_word_to_device STOP_PLC_FLAG, to_plc_status
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device from_plc_status
          break if (v & STOP_PLC_FLAG) != 0
          sleep 0.1
        end
      end

      def clear_program
        @protocol.set_word_to_device STOP_PLC_FLAG | CLEAR_PROGRAM_FLAG, to_plc_status
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device from_plc_status
          break if (v & CLEAR_PROGRAM_FLAG) != 0
          sleep 0.1
        end
        @protocol.set_word_to_device STOP_PLC_FLAG, to_plc_status
      end

      def run_plc
        @protocol.set_word_to_device 0, to_plc_status
        Timeout.timeout(5) do
          v = @protocol.get_word_from_device from_plc_status
          break if (v & CYCLE_RUN_FLAG) != 0
          sleep 0.1
        end
      end

      def write_program
        word_data.each_slice(2*1024) do |chunk|
          @protocol.set_words_to_device chunk, @program_area
        end
      end

  end


end
