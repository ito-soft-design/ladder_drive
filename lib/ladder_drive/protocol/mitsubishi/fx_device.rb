module LadderDrive
module Protocol
module Mitsubishi

  class FxDevice < QDevice
    
    def name
      @suffix + @number.to_s.rjust(4, "0")
    end
  end

end
end
end
