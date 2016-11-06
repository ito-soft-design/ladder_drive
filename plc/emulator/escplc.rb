module Plc
module Emulator

  class EscalatorPlc

    attr_accessor :program_data
    attr_reader :program_pointer
    attr_reader :device_dict
    attr_reader :errors

    SUFFIXES = %w(x y m c t l sc cc tc d cs ts h sd)

    SUFFIXES.each do |k|
      attr_reader :"#{k}_devices"
    end


    def initialize
      @program_data = []
      SUFFIXES.each do |k|
        eval "@#{k}_devices = []"
      end
      @device_dict = {}
      reset
    end

    def device_by_name name
      d = device_dict[name]
      unless d
        d = Device.parse name
        device_dict[name] = d
      end
      d
    end

    def device_by_type_and_number type, number
      d = Device.new type, number
      device_by_name d.name
    end

    def reset
      @bool = false
      @word = 0
      @program_pointer = 0
    end

    def run_cycle
      @program_pointer = 0
      while fetch_and_execution; end
    end

    private

      def mnenonic_table
        @mnemonic_table ||= begin
          s = <<EOB
|00|END|INV|MEP|ANB|MEF|ORB|FEND|NOP|
|10|LD|LDI|LDP|LDPI|LDF|LDFI|MC|MCR|
|20|AND|ANI|ANDP|ANPI|ANDF|ANFI|
|30|OR|ORI|ORP|ORPI|ORF|ORFI|
|40|OUT|OUTI|MPS|MPD|MPP| |
|50|SET|RST|PLS| |PLF||
|60|FF||||||
|70|
|80|SFT|SFTP|SFL|SFLP|SFR|SFRP|
|90|BSFL|BSFLP|DSFL|DSFLP|BSFR|BSFRP|DSFR|DSFRP|
|A0|SFTL|SFTLP|WSFL|WSFLP|SFTR|SFTRP|WFSR|WSFRP|
EOB
          table = {}
          s.lines.each_with_index do |line, h|
            line.split("|")[2..-1].each_with_index do |mnemonic, l|
              unless mnemonic.length == 0
                table[h << 4 | l] = mnemonic.downcase.to_sym
              end
            end
          end
          table
        end
      end

      def fetch_and_execution
        code = fetch_1_byte
        return false unless code
        mnemonic = mnenonic_table[code]
p [mnemonic, @bool]
        if mnemonic && respond_to?(mnemonic, true)
          send mnemonic
        else
          nil
        end
      end

      def fetch_1_byte
        if @program_pointer < program_data.size
          program_data[@program_pointer].tap do
            @program_pointer += 1
          end
        else
          nil
        end
      end

      def fetch_device_or_value
        c = fetch_1_byte
        return false unless c

        # check value type
        case c & 0xe0
        when 0x80
          # bit device
        when 0x00
          # immediate number
          return c
        else
          add_error "invalidate value type #{c.to_h(16)}"
          return false
        end

        # device type
        device_type = c & 0x0f

        # number
        number = 0
        if (c & 0x10) == 0
          number = fetch_1_byte
        else
          number = fetch_2_byte
        end

        # make device
        d = device_by_type_and_number device_type, number
        unless d
          add_error "invalid device type #{c&0x3} and number #{number}"
          return false
        end
        d
      end

      def fetch_bool_value inverse=false
        d = fetch_device_or_value
        return false unless d
        unless d.is_a? Device
          add_error "ld must be specify a device nor number #{d}"
          return false
        end
p [d.name, d.bool]
        inverse ? !d.bool : !!d.bool
      end

      def add_error reason
        @errors << {pc:@program_pointer, reason:reason}
      end


      # --- mnenonic ---
      def ld inverse=nil
        b = fetch_bool_value inverse
        return false if b.nil?
        @bool = b
      end
      def ldi; ld true; end

      def and inverse=nil
p __LINE__
        b = fetch_bool_value inverse
        return false if b.nil?
p [@bool , b]
        @bool = @bool && b
      end
      def ani; send :and, true; end


  end

end
end
