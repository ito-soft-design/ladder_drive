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
  end

  def set_values h
    h.each do |k, v|
      d = @plc.device_by_name k.to_s
      d.set_value v, :in
    end
  end

  def test_ld_x0
    @plc.program_data = LadderDrive::Asm.new("LD X0").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_ldi_x0
    @plc.program_data = LadderDrive::Asm.new("LDI X0").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal true, @plc.bool

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_inv
    @plc.program_data = LadderDrive::Asm.new("LD X0\nINV").codes
    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.bool
  end

  def test_nop
    @plc.program_data = LadderDrive::Asm.new("NOP\nLD X0").codes
    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_and_x0_x1
    @plc.program_data = LadderDrive::Asm.new("LD X0\nAND X1").codes

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
    @plc.program_data = LadderDrive::Asm.new("LD X0\nANI X1").codes

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
    @plc.program_data = LadderDrive::Asm.new("LD X0\nOR X1").codes

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
    @plc.program_data = LadderDrive::Asm.new("LD X0\nORI X1").codes

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
    @plc.program_data = LadderDrive::Asm.new("LD X0\nOUT Y0").codes

    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("Y0").bool
    assert_equal 0, @plc.device_by_name("SD4").word
  end

  def test_out_is_no_effected_to_input_device
    @plc.program_data = LadderDrive::Asm.new("LD X0\nOUT X1").codes

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("X1").bool
  end

  def test_outi
    @plc.program_data = LadderDrive::Asm.new("LD X0\nOUTI Y0").codes

    set_values X0:false
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("Y0").bool
  end

  def test_end
    @plc.program_data = LadderDrive::Asm.new("END\nLD X0").codes

    set_values X0:false
    @plc._run_cycle
    # default value = true
    assert_equal true, @plc.bool
  end

  def test_anb
    @plc.program_data = LadderDrive::Asm.new("LD X0\nOR X1\nLD X2\nOR X3\nANB\nOUT Y0").codes

    set_values X0:false, X1:false, X2:false, X3:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("Y0").bool

    set_values X0:true, X1:false, X2:false, X3:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("Y0").bool

    set_values X0:false, X1:false, X2:true, X3:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("Y0").bool

    set_values X0:true, X1:false, X2:true, X3:false
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("Y0").bool
  end

  def test_orb
    @plc.program_data = LadderDrive::Asm.new("LD X0\nLD X1\nORB").codes

    set_values X0:false, X1:false
    @plc._run_cycle
    assert_equal false, @plc.bool

    set_values X0:true, X1:false
    @plc._run_cycle
    assert_equal true, @plc.bool
  end

  def test_orb_2
    @plc.program_data = LadderDrive::Asm.new("LD M0\nOR M1\nAND M2\nLD M3\nOR M4\nORB\nOUT M5").codes

    set_values M0:true, M1:false, M2:true, M3:false, M4:false
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("M5").bool

    set_values M0:false, M1:false, M2:false, M3:true, M4:false
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("M5").bool

  end

  def test_mps
    @plc.program_data = LadderDrive::Asm.new("LD X0\nMPS\n").codes
    set_values X0:true
    @plc._run_cycle
    assert_equal 1, @plc.device_by_name("SD4").word
    assert_equal true, @plc.bool
  end

  def test_mrd_and_mpp
    @plc.program_data = LadderDrive::Asm.new("LD X0\nMPS\nOUT Y0\nMRD\nINV\nOUT Y1\nMPP\nAND X1\nOUT Y2").codes
    set_values X0:true, X1:true
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("Y0").bool
    assert_equal false, @plc.device_by_name("Y1").bool
    assert_equal true, @plc.device_by_name("Y2").bool
  end

  def test_set
    @plc.program_data = LadderDrive::Asm.new("LD X0\nSET M0").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("M0").bool

    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("M0").bool
    assert_equal 0, @plc.device_by_name("SD4").word
  end

  def test_should_not_set_if_device_is_input
    @plc.program_data = LadderDrive::Asm.new("LD X0\nSET X1").codes
    set_values X0:false
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("X1").bool

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("X1").bool
    assert_equal 0, @plc.device_by_name("SD4").word
  end

  def test_rst
    @plc.program_data = LadderDrive::Asm.new("LD X0\nRST M0").codes
    set_values M0:true, X0:false
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("M0").bool

    set_values X0:true
    @plc._run_cycle
    assert_equal false, @plc.device_by_name("M0").bool
    assert_equal 0, @plc.device_by_name("SD4").word
  end

  def test_should_not_rst_if_device_is_input
    @plc.program_data = LadderDrive::Asm.new("LD X0\nRST X1").codes
    set_values X0:false, X1:true
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("X1").bool

    set_values X0:true
    @plc._run_cycle
    assert_equal true, @plc.device_by_name("X1").bool
    assert_equal 0, @plc.device_by_name("SD4").word
  end


end
