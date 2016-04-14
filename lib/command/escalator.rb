module Escalator

  class Asm

    attr_reader :codes
    
    def initialize stream
      @lines = []
      address = 0
      stream.each do | line|
        @lines << AsmLine.new(line, address)
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
    
    def initialize line, address = 0
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
p [:c, c]
        c.to_s(16).rjust(2, "0")
      end
      .join(" ")
      .ljust(12)
    end
    
    def next_address
      address + codes.size
    end

    private
    
      OPERAND_TPE_NONE                    = 0
      OPERAND_TYPE_TYPE_AND_NUMBER        = 1
      OPERAND_TYPE_TYPE_AND_NUMBER_NUMBER = 2
      
      def parse
        a = line.split(/\s/)
        mnemonic, operand1, operand2 = a
        @codes << encode_mnemonic(mnemonic) if mnemonic
        case operand_type(mnemonic)
        when OPERAND_TYPE_TYPE_AND_NUMBER
p 1
          @codes += parse_type_and_number(operand1)
p @codes
        end
      end
      
      def operand_type mnemonic
        case mnemonic
        when /LD/, /AND/, /OR/, /OUT/, "SET", "RST", "PLS", "PLF", "FF", /SF(L|R)/
          OPERAND_TYPE_TYPE_AND_NUMBER
        else
          OPERAND_TPE_NONE
        end
      end
    
      MNEMONIC_DEF = <<EOB
| |00|10|20|30|40|50|60|70|80|90|A0|B0|C0|D0|E0|F0|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|00|NOP|INV|MEP|ANB|MEF|ORB|FEND|END|
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
        /(\w*)(\d+[0-9A-Fa-f]*)\.?(\d*)?/ =~ operand
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
p [operand, suffix]
        raise "undefind suffix: #{suffix}" if type_code.nil?
        
        case (type_code & 0xc >> 2)
        when 0, 1
          type_code |= 0x80
        else
          type_code |= 0xa0
        end
        
        if number < 256
          [type_code, number]
        else
          [type_code | 0x10, number & 0xff, (number & 0xff00) >> 8]
        end
      end
    
  end


end

if $0 == __FILE__
  asm = Escalator::Asm.new ARGF
  puts asm.dump_line
end
