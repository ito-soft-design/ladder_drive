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

  class Asm

    attr_reader :codes
    attr_reader :endian

    LITTLE_ENDIAN   = 0
    BIG_ENDIAN      = 1

    def initialize source, endian = nil
      @endian = endian || LITTLE_ENDIAN
      @lines = []
      address = 0
      source.each_line do | line|
        @lines << AsmLine.new(line, address, @endian)
        address = @lines.last.next_address
      end
    end

    def dump
      @codes.map do |c|
        c.to_s(16).rjust(2, "0")
      end
    end

    def dump_line
      @lines.map do |line|
        "#{line.address.to_s(16).rjust(4, "0")} #{line.dump_line}"
      end
      .join("\n") << "\n"
    end

    def codes
      @lines.map do |line|
        line.codes
      end.flatten
    end

    private

      def parse line
        @lines << AsmLine.new(line)
      end


  end

  class AsmLine
    attr_reader :line
    attr_reader :codes
    attr_reader :address
    attr_reader :endian

    def initialize line, address = 0, endian = nil
      @endian = endian || Asm::LITTLE_ENDIAN
      @line = line.upcase.chomp
      @codes = []
      @address = address
      parse
    end

    def dump_line
      "#{dump}\t#{line}"
    end

    def dump
      @codes.map do |c|
        c.to_s(16).rjust(2, "0")
      end
      .join(" ")
      .ljust(12)
    end

    def next_address
      address + codes.size
    end

    private

      OPERAND_TYPE_NONE                   = 0
      OPERAND_TYPE_TYPE_AND_NUMBER        = 1
      OPERAND_TYPE_TYPE_AND_NUMBER_NUMBER = 2

      def parse
        a = line.split(/\s+/)
        mnemonic, operand1, operand2 = a
        @codes << encode_mnemonic(mnemonic) if mnemonic
        case operand_type(mnemonic)
        when OPERAND_TYPE_TYPE_AND_NUMBER
          @codes += parse_type_and_number(operand1)
        end
      end

      def operand_type mnemonic
        case mnemonic
        when /LD/, /AND/, /OR[^B]?$/, /OUT/, "SET", "RST", "PLS", "PLF", "FF", /SF(L|R)/
          OPERAND_TYPE_TYPE_AND_NUMBER
        else
          OPERAND_TYPE_NONE
        end
      end

      MNEMONIC_DEF = <<EOB
| |00|10|20|30|40|50|60|70|80|90|A0|B0|C0|D0|E0|F0|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|00|END|INV|MEP|ANB|MEF|ORB|FEND|NOP|
|01|LD|LDI|LDP|LDPI|LDF|LDFI|MC|MCR|
|02|AND|ANI|ANDP|ANPI|ANDF|ANFI|
|03|OR|ORI|ORP|ORPI|ORF|ORFI|
|04|OUT|OUTI|MPS|MPD|MPP| |
|05|SET|RST|PLS| |PLF||
|06|FF||| |||
|07|
|08|SFT|SFTP|SFL|SFLP|SFR|SFRP|
|09|BSFL|BSFLP|DSFL|DSFLP|BSFR|BSFRP|DSFR|DSFRP|
|0A|SFTL|SFTLP|WSFL|WSFLP|SFTR|SFTRP|WFSR|WSFRP|
|0B|
|0C|
|0D|
|0E|
|0F|
EOB
      def mnemonic_dict
        @@mnemonic_dict ||= begin
          h = {}
          MNEMONIC_DEF.dup.split(/\n/)[2..-1].each_with_index do |line, upper|
            line.split(/\|/)[2..-1].each_with_index do |mnemonic, lower|
              mnemonic.strip!
              next if mnemonic.nil? || mnemonic.length == 0
              code = (upper << 4) | lower
              h[mnemonic] = code
            end
          end
          h
        end
      end

      def encode_mnemonic mnemonic
        mnemonic_dict[mnemonic]
      end

      def parse_type_and_number operand
        /([[:alpha:]]*)(\d+[0-9A-Fa-f]*)\.?(\d*)?/ =~ operand
        suffix = $1
        number = $2
        bit = $3
        len = 16
        case suffix
        when "X", "Y"
          number = number.to_i(16)
        else
          number = number.to_i
        end
        type_code = %W(X Y M - C T L SC CC TC D NOP - CS TS H SD).index(suffix)
        raise "undefind suffix: #{suffix}" if type_code.nil?

        case (type_code & 0xc) >> 2
        when 0, 1
          type_code |= 0x80
        else
          type_code |= 0xa0
        end

        if number < 256
          [type_code, number]
        else
          case endian
          when Asm::LITTLE_ENDIAN
            [type_code | 0x10, number & 0xff, (number & 0xff00) >> 8]
          when Asm::BIG_ENDIAN
            [type_code | 0x10, (number & 0xff00) >> 8, number & 0xff]
          end
        end
      end

  end


end

if $0 == __FILE__
  asm = Escalator::Asm.new ARGF
  puts asm.dump_line
end
