require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'plc'

include Plc::Emulator

class EmuPlc
  def _run_cycle; run_cycle; end
  def _stacks; @stacks; end
end


class TestCycleRun < Test::Unit::TestCase

  setup do
    @plc = EmuPlc.new
    #@plc = Plc::Emulator::EmuPlc.new
  end

  def test_it_should_receive_st
    r = @plc.execute_console_commands "ST M0"
    assert_equal "OK\r\n", r
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("M0").bool
  end

  def test_it_should_receive_rds_with_bit
    @plc.execute_console_commands "ST M1"
    @plc._run_cycle
    r = @plc.execute_console_commands "RDS M0 1"
    # it returns word value.
    assert_equal "2\r\n", r
  end

  def test_it_should_receive_rds_with_word
    @plc.execute_console_commands "WRS D0 4 1 2 3 4"
    @plc._run_cycle
    r = @plc.execute_console_commands "RDS D0 4"
    assert_equal "1 2 3 4\r\n", r
  end

  def test_it_should_receive_wrs_to_prg
    @plc.execute_console_commands "WRS PRG0 4 1 2 3 4"
    @plc._run_cycle
    r = @plc.execute_console_commands "RDS PRG0 4"
    assert_equal "1 2 3 4\r\n", r
    assert_equal [0,1,0,2,0,3,0,4], @plc.program_data
  end

  def test_it_should_be_run_script
    r = @plc.execute_console_commands "E 1+2"
    assert_equal "3", r
  end

end
