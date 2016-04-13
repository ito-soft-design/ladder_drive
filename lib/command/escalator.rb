module Escalator

  class Asm

    attr_reader :codes
    
    def initialize
      @codes = []
    end
    
    def parse line
      
      a = line.split(/\s/)
      @codes << encode_mnemonic(a[0])
      @codes.flatten!
    end

    def encode_mnemonic mnemonic
      a = []
      code = mnemonic_dict[mnemonic]
      a << code if code
      a
    end
    
    def dump 
      @codes.map do |c|
        c.to_s(16).rjust(2, "0")
      end
    end

    
    private
    
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
        @mnemonic_dict ||= begin
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

  end
  
end


asm = Escalator::Asm.new

ARGF.each do |line|
  asm.parse(line)
end
puts asm.dump
