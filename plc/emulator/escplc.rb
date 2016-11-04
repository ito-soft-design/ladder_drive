module Plc
module Emulator

  class EscalatorPlc

    attr_accessor :program_data
    attr_reader :program_pointer

    SUFFIXES = %w(x y m c t l sc cc tc d cs ts h sd)

    SUFFIXES.each do |k|
      attr_reader :"#{k}_devices"
    end

    def initialize
      @program_data = []
      SUFFIXES.each do |k|
        eval "@#{k}_devices = []"
      end
    end



  end

end
end
