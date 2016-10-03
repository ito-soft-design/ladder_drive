module Escalator

  class IntelHex

    attr_reader :offset, :codes

    def initialize codes, offset = 0
      @offset = offset
      @codes = codes
    end

    def dump
      addr = offset
      lines = []
      @codes.each_slice(16) do |line_codes|
        c = line_codes.size
        s = ":#{c.to_s(16).rjust(2, '0')}"
        s << "#{addr.to_s(16).rjust(4, '0')}"
        s << "00"
        line_codes.each do |code|
          s << "#{code.to_s(16).rjust(2, '0')}"
        end
        check_sum = 256 - (s[1..-1].scan(/.{2}/).inject(0){|sum, code| sum += code.to_i(16)} & 0xff)
        s << "#{check_sum.to_s(16).rjust(2, '0')}"
        lines << s
        addr += c
      end

      lines << ":00000001FF"
      lines << ""
      lines.join("\n")
    end

    def gxworks_memory_image
      lines = []
      @codes.each_slice(8) do |line_codes|
        lines << line_codes.join("\t")
      end

      lines.join("\n")
    end

  end

end
