require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

include Plc::Emulator

class EscalatorPlc
  def _run_cycle; run_cycle; end
end

class TestCycleRun < Test::Unit::TestCase

  setup do
    @plc = EscalatorPlc.new
  end

  def set_values h
    h.each do |k, v|
      d = @plc.device_by_name k.to_s
      d.value = v
    end
  end

  def test_ld_x0
    @plc.program_data = Escalator::Asm.new("LD X0").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_ldi_x0
    @plc.program_data = Escalator::Asm.new("LDI X0").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_inv
    @plc.program_data = Escalator::Asm.new("LD X0\nINV").codes
    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_nop
    @plc.program_data = Escalator::Asm.new("NOP\nLD X0").codes
    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_and_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nAND X1").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_ani_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nANI X1").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_or_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nOR X1").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_ori_x0_x1
    @plc.program_data = Escalator::Asm.new("LD X0\nORI X1").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_out
    @plc.program_data = Escalator::Asm.new("LD X0\nOUT Y0").codes

    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.bool
    assert_equal false, @plc.device_by_name("Y0").bool
  end

  def test_out_is_no_effected_to_input_device
    @plc.program_data = Escalator::Asm.new("LD X0\nOUT X1").codes

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("X1").bool
  end

  def test_outi
    @plc.program_data = Escalator::Asm.new("LD X0\nOUTI Y0").codes

    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.bool
    assert_equal true, @plc.device_by_name("Y0").bool
  end

  def test_end
    @plc.program_data = Escalator::Asm.new("END\nLD X0").codes

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_anb
    @plc.program_data = Escalator::Asm.new("LD X0\nOR X1\nANB\nLD X2\nOR X3\nOUT Y0").codes

    set_values X0:false, X1:false, X2:false, X3:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false, X2:false, X3:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:false, X1:false, X2:true, X3:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false, X2:true, X3:false
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_orb
    @plc.program_data = Escalator::Asm.new("LD X0\nLD X1\nORB").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

end
