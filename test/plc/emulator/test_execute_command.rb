require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'plc'

include Plc::Emulator

class TestCycleRun < Test::Unit::TestCase

  setup do
    @plc = EmuPlc.new
    #@plc = Plc::Emulator::EmuPlc.new
  end

  def test_it_should_receive_st
    r = @plc.execute_console_commands "ST M0"
    assert_equal "OK\r", r
    assert_equal true, @plc.device_by_name("M0").bool
  end

  def test_it_should_receive_rds_with_bit
    @plc.execute_console_commands "ST M1"
    r = @plc.execute_console_commands "RDS M0 2"
    assert_equal "0 1\r", r
  end

  def test_it_should_receive_rds_with_word
    @plc.execute_console_commands "WRS D0 4 1 2 3 4"
    r = @plc.execute_console_commands "RDS D0 4"
    assert_equal "1 2 3 4\r", r
  end

end
