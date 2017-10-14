require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

class TestEmuDevice < Test::Unit::TestCase

  setup do
    @plc = EmuPlc.new
    @device = @plc.device_by_name "M16"
  end

  def test_bool
    assert_equal false, @device.bool
  end

  def test_set_bool
    @device.bool = true
    assert_equal true, @device.bool
  end

  def test_word
    @device.word = 0x1234
    assert_equal @device.word, 0x1234
    assert_equal false, (@device + 15).bool
    assert_equal false, (@device + 14).bool
    assert_equal false, (@device + 13).bool
    assert_equal true,  (@device + 12).bool
    assert_equal false, (@device + 11).bool
    assert_equal false, (@device + 10).bool
    assert_equal true,  (@device + 9).bool
    assert_equal false, (@device + 8).bool
    assert_equal false, (@device + 7).bool
    assert_equal false, (@device + 6).bool
    assert_equal true,  (@device + 5).bool
    assert_equal true,  (@device + 4).bool
    assert_equal false, (@device + 3).bool
    assert_equal true,  (@device + 2).bool
    assert_equal false, (@device + 1).bool
    assert_equal false, (@device + 0).bool
  end

end
