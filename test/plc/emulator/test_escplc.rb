require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

include Plc::Emulator

class TestEmuPlc < Test::Unit::TestCase

  setup do
    @plc = EmuPlc.new
  end

  def test_program_data
    assert_equal [], @plc.program_data
  end

  %w(x y m c t l sc cc tc d cs ts h sd).each do |k|
    define_method :"test_#{k}_devices" do
      assert_equal [], @plc.send("#{k}_devices")
    end
  end

  def test_name
    d = Device.new DeviceType::X, 1
    assert_equal "X1", d.name
  end

  def test_ld
    source = <<EOB
LD X0
EOB
    @plc.program_data = Escalator::Asm.new(source).codes
    assert_equal [0x10, 0x80, 0x00], @plc.program_data
  end

end
