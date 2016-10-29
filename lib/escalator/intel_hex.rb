module Escalator

  class IntelHex

    attr_reader :offset, :codes

    def self.load path
      offset = 0
      codes = []
      File.read(path).lines.each do |l|
        case l[7,2]
        when "00"
          address = l[3,4].to_i(16)
          offset ||= address
          l.chomp[9..-3].each_char.each_slice(2).each_with_index do |pair, i|
            codes[address - offset + i] = pair.join("").to_i(16)
          end
        end
      end
      new codes, offset
    end

    def initialize codes, offset = 0
      @offset = offset
      @codes = codes
    end

    def write_to path
      File.write(path, dump)
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

  end

end
