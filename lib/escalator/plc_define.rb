module Escalator
  module PlcDefine

    # status flags
    # SD0
    ESC_STATUS_TO_PLC_STOP_PLC_FLAG       = 2     # bit 1
    ESC_STATUS_TO_PLC_CLEAR_PROGRAM       = 4     # bit 2  require bit 1 on
    # SD1
    ESC_STATUS_FROM_PLC_CYCLE_RUN         = 2
    ESC_STATUS_FROM_PLC_ACK_CLEAR_PROGRAM = 4

  end
end
