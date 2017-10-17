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

require 'ladder_drive/plc_device'
require 'yaml'

include LadderDrive

module Plc
module Emulator

  class EmuPlc

    attr_accessor :program_data
    attr_reader :program_pointer
    attr_reader :config
    attr_reader :device_dict
    attr_reader :errors

    SUFFIXES = %w(x y m c t l sc cc tc d cs ts h sd)

    SUFFIXES.each do |k|
      attr_reader :"#{k}_devices"
    end

    STOP_PLC_FLAG         = 2     # bit 1
    CLEAR_PROGRAM_FLAG    = 4     # bit 2  require bit 1 on

    CYCLE_RUN_FLAG        = 2

    INDEX_BIT_STACK_COUNT = 4
    INDEX_BIT_STACK       = 5
    SIZE_OF_BIT_STACK     = 3

    SAVE_INTERVAL = 1.0 #60.0

    def initialize config={}
      SUFFIXES.each do |k|
        eval "@#{k}_devices = []"
      end
      @lock = Mutex.new
      @config = config
      reset
    end

    def device_by_name name
      @lock.synchronize {
        d = device_dict[name]
        unless d
          # try normalized name again
          new_d = EmuDevice.new(name)
          d = device_dict[new_d.name]
          unless d
            d = new_d
            d.plc = self
            device_dict[d.name] = d
          end
        end
        d
      }
    end

    def device_by_type_and_number type, number
      d = EmuDevice.new type, number
      device_by_name d.name
    end

    def reset
      @word = 0
      @program_data = []
      @device_dict ||= {}
      @lock.synchronize {
        @device_dict.values.each do |d|
          d.reset
        end
      }
    end

    def run_cycle
      status_to_plc = device_by_name "SD0"
      status_form_plc = device_by_name "SD1"
      sync_input
      case status_to_plc.value & (STOP_PLC_FLAG | CLEAR_PROGRAM_FLAG)
      when STOP_PLC_FLAG
        status_form_plc.value = 0
        sleep 0.1
      when STOP_PLC_FLAG | CLEAR_PROGRAM_FLAG
        reset
        load
        status_form_plc.value = CLEAR_PROGRAM_FLAG
        sleep 0.1
      when 0
        status_form_plc.value = CYCLE_RUN_FLAG
        @program_pointer = 0
        clear_stacks
        while fetch_and_execution; end
        sleep 0.0001
      else
        sleep 0.1
      end
      # Save must be executed berofe sync_output, because changed flag was clear after sync_output
      save
      sync_output
    end

    def bool
      (stack_device.word & 1) != 0 ? true : false
    end

    def bool= value
      if value
        stack_device.word |= 1
      else
        stack_device.word &= 0xfffe;
      end
    end

    def run
      Thread.new do
        loop do
          run_cycle
        end
      end
    end

    def execute_console_commands line
      a = line.chomp.split(/\s+/)

      # separate data type except eval command.
      unless a[0] == "E"
        word = /([A-Z0-9]+)(\.H)?/ =~ a[1]
        a[1] = $1
      end

      case a[0]
      when /^ST/i
        d = device_by_name a[1]
        d.set_value true, :in
        "OK\r\n"
      when /^RS/i
        d = device_by_name a[1]
        d.set_value false, :in
        "OK\r\n"
      when /^RDS/i
        d = device_by_name a[1]
        c = a[2].to_i
        r = []
        if !word && d.bit_device?
          c.times do
            r << (d.bool(:out) ? 1 : 0)
            d = device_by_name (d+1).name
          end
        else
          case d.suffix
          when "PRG"
            c.times do
              r << program_data[d.number * 2, 2].pack("C*").unpack("n").first
              d = device_by_name (d+1).name
            end
          else
            c.times do
              r << d.word(:out)
              d = device_by_name (d+1).name
            end
          end
        end
        r.map{|e| e.to_s(16)}.join(" ") + "\r\n"

      # LadderDrive communication is bases KV protocol.
      # LadderDrive console is use WRS command only. (Not use WR command)
      # WR command is for irBoard. (http://irboard.itosoft.com)
      # A word value is communicated with hex format only in this product. (hard coding)
      when /^WRS?/i
        d = device_by_name a[1]
        a.insert 2, "1" if /^WR$/i =~ a.first
        c = a[2].to_i
        case d.suffix
        when "PRG"
          a[3, c].each do |v|
            program_data[d.number * 2, 2] = [v.to_i(16)].pack("n").unpack("C*")
            d = device_by_name (d+1).name
          end
        else
          if !word && d.bit_device?
            a[3, c].each do |v|
              d.set_value v == "0" ? false : true, :in
              d = d + 1#device_by_name (d+1).name
            end
          else
            a[3, c].each do |v|
              v = v.to_i(16)
              d.set_word v, :in
              #d.set_value v, :in
              d = d + 1#device_by_name (d+1).name
            end
          end
        end
        "OK\r\n"
      when /E/
        eval(a[1..-1].join(" ")).inspect
      else
        raise "Unknown command #{a.first}"
      end
    end

    # --- queries
    def keep_device? device
      @keep_ranges ||= begin
        if config[:keep]
          config[:keep].map do |a|
            [device_by_name(a.first), device_by_name(a.last)]
          end
        else
          []
        end
      end
      @keep_ranges.each do |a|
        f = a.first
        e = a.last
        next unless f.suffix == device.suffix
        return true if (f.number..e.number).include? device.number
      end
      false
    end

    private

      # ----------------
      # Load / Save keep devices

      def dump_memory_path
        @dump_memory_paty ||= File.join("cache", "dump_memory.yml").tap do |path|
          FileUtils.mkdir_p( File.dirname(path))
        end
      end

      def load
        path = dump_memory_path
        return unless File.exist? path

        YAML.load(File.read(path)).each do |a|
          d = device_by_name(a.first)
          d.value = a.last
        end
      end

      def save
        devices = @device_dict.values.select{|d| self.keep_device?(d)}
        needs_save = @pending_save || !(devices.select{|d| d.changed?}).empty?
        return unless needs_save
        now = Time.now
        if @saved_at && ((now - @saved_at) < SAVE_INTERVAL)
          @pending_save ||= true
          return
        end

        File.write dump_memory_path, YAML.dump(devices.map{|d| [d.name, d.value]})
        @saved_at = now
        @pending_save = false
      end


      # ----------------
      # stack operations
      def stack_device index=0
        device_by_name (device_by_name("SD0") + INDEX_BIT_STACK + index).name
      end

      def stack_count_device
        device_by_name (device_by_name("SD0") + INDEX_BIT_STACK_COUNT).name
      end

      def push_stack flag = false
        stack_device.word <<= 1
        if flag
          stack_device.word |= 1
        else
          stack_device.word &= 0xfffe
        end
        stack_device.word &= 0xffff
      end

      def pop_stack
        stack_device.word >>= 1
        stack_device.word |= 0x8000
      end

      def clear_stacks
        stack_device.word = 0xffff
        stack_count_device.word = 0
      end

      def push_stacks
        if stack_count_device.word > SIZE_OF_BIT_STACK
          puts "ERROR: stacks overflow pc: H#{program_pointer.to_s(16).rjust(4, "0")}"
          return
        end
        values = []
        (SIZE_OF_BIT_STACK - 1).downto 0 do |i|
          values << stack_device(i).word
        end
        values.shift
        values << 0xffff
        SIZE_OF_BIT_STACK.times do |i|
          stack_device(i).word = values.pop
        end
        stack_count_device.word += 1
      end

      def pop_stacks
        if stack_count_device.word <= 0
          puts "ERROR: stacks underflow pc: H#{program_pointer.to_s(16).rjust(4, "0")}"
          return
        end
        values = []
        (SIZE_OF_BIT_STACK - 1).downto 0 do |i|
          values << stack_device(i).word
        end
        v = values.pop
        values.each_with_index do |v, i|
          stack_device(i).word = v
        end
        stack_count_device.word -= 1
        v
      end
      # ----------------

      def sync_input
        @lock.synchronize {
          device_dict.values.each do |d|
            d.sync_input
          end
        }
      end

      def sync_output
        @lock.synchronize {
          device_dict.values.each do |d|
            d.sync_output
          end
        }
      end

      def and_join_stack
        d = stack_device
        b = d.word == 0xffff
        d.word = 0xffff
        push_stack b
      end

      def mnenonic_table
        @mnemonic_table ||= begin
          s = <<EOB
|00|END|INV|MEP|ANB|MEF|ORB|FEND|NOP|
|10|LD|LDI|LDP|LDPI|LDF|LDFI|MC|MCR|
|20|AND|ANI|ANDP|ANPI|ANDF|ANFI|
|30|OR|ORI|ORP|ORPI|ORF|ORFI|
|40|OUT|OUTI|MPS|MRD|MPP| |
|50|SET|RST|PLS| |PLF||
|60|FF||||||
|70|
|80|SFT|SFTP|SFL|SFLP|SFR|SFRP|
|90|BSFL|BSFLP|DSFL|DSFLP|BSFR|BSFRP|DSFR|DSFRP|
|A0|SFTL|SFTLP|WSFL|WSFLP|SFTR|SFTRP|WFSR|WSFRP|
EOB
          table = {}
          s.lines.each_with_index do |line, h|
            line.chomp.split("|")[2..-1].each_with_index do |mnemonic, l|
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
        if mnemonic && respond_to?(mnemonic, true)
          r = send mnemonic
          r
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
        unless d.is_a? EmuDevice
          add_error "ld must be specify a device nor number #{d}"
          return false
        end
        inverse ? !d.bool : d.bool
      end

      def add_error reason
        @errors << {pc:@program_pointer, reason:reason}
      end


      # --- mnenonic ---
      def ld inverse=false
        b = fetch_bool_value inverse
        return false if b.nil?
        push_stack b
        true
      end
      def ldi; ld true; end

      def inv
        and_join_stack
        self.bool = !self.bool
        true
      end

      def and inverse=false
        b = fetch_bool_value inverse
        return false if b.nil?
        self.bool &= b
        true
      end
      def ani; send :and, true; end

      def or inverse=false
        b = fetch_bool_value inverse
        return false if b.nil?
        self.bool |= b
        true
      end
      def ori; send :or, true; end

      def anb
        b = self.bool
        pop_stack
        self.bool &= b
        true
      end

      def orb
        b = self.bool
        pop_stack
        self.bool |= b
        true
      end

      def nop; true; end

      def mps
        and_join_stack
        b = self.bool
        push_stacks
        push_stack b
        true
      end

      def mrd
        b = self.bool
        pop_stacks
        push_stacks
        push_stack b
        true
      end
      def mpp; mrd; end

      def out inverse=false
        and_join_stack
        d = fetch_device_or_value
        unless d.is_a? EmuDevice
          add_error "ld must be specify a device nor number #{d}"
          return false
        end
        d.bool = inverse ? !self.bool : self.bool unless d.input?
        pop_stack
        true
      end
      def outi; out true; end

      def set inverse=false
        and_join_stack
        d = fetch_device_or_value
        unless d.is_a? EmuDevice
          add_error "ld must be specify a device nor number #{d}"
          return false
        end
        d.bool = !inverse if self.bool unless d.input?
        pop_stack
        true
      end
      def rst; set true; end



  end

end
end
