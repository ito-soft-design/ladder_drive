require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

class TestEmuDevice < Test::Unit::TestCase

  setup do
    @plc = EmuPlc.new
    @device = @plc.device_by_name "M16"
    @w_device = @plc.device_by_name "D0"
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

  def test_changed
    assert_equal false, @device.changed?
    @device.value = 1
    assert_equal true, @device.changed?
    # after sync_output, it should be reset.
    @device.sync_output
    assert_equal false, @device.changed?
  end

  def test_text
    d = @w_device
    d.value = 0x3130
    d = d.next_device
    d.value = 0x3332
    assert_equal "0123", @w_device.text(4)
  end

  def test_text_with_len
    d = @w_device
    d.value = 0x3130
    d = d.next_device
    d.value = 0x3332
    assert_equal "0", @w_device.text(1)
  end

  def test_text_with_null
    d = @w_device
    d.value = 0x0000
    d = d.next_device
    d.value = 0x0000
    assert_equal "", @w_device.text(4)
  end

  def test_set_text
    @w_device.text = "0123"
    assert_equal 0x3130, @w_device.value
    assert_equal 0x3332, @w_device.next_device.value
  end

  def test_set_text_with_len
    @w_device.set_text "0123", 1
    assert_equal 0x30, @w_device.value
    assert_equal 0x00, @w_device.next_device.value
  end




end
