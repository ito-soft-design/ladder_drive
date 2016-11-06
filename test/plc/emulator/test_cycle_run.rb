require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

include Plc::Emulator

class EscalatorPlc
  def _run_cycle; run_cycle; end
  def _bool; @bool; end
end

class TestCycleRun < Test::Unit::TestCase

  setup do
    @plc = EscalatorPlc.new
  end

  def test_ld_x0
    @plc.program_data = Escalator::Asm.new("LD X0").codes
    d = @plc.device_by_name "X0"
    d.bool = false
    @plc._run_cycle
    assert_equal false, @plc._bool
    d.bool = true
    @plc._run_cycle
    assert_equal true, @plc._bool
  end

  def test_ldi_x0
    @plc.program_data = Escalator::Asm.new("LDI X0").codes
    d = @plc.device_by_name "X0"

    d.bool = false
    @plc._run_cycle
    assert_equal true, @plc._bool

    d.bool = true
    @plc._run_cycle
    assert_equal false, @plc._bool
  end

  def test_and_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nAND X1").codes
p @plc.program_data

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc._bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal false, @plc._bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal false, @plc._bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal true, @plc._bool
  end

  def test_ani_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nANI X1").codes
p @plc.program_data

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc._bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal false, @plc._bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc._bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal false, @plc._bool
  end


  def set_values h
    h.each do |k, v|
      d = @plc.device_by_name k.to_s
      d.value = v
    end
  end

end
