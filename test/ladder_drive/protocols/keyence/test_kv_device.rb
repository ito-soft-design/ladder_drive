require 'test/unit'
require 'ladder_drive'

include LadderDrive::Protocol::Keyence

class TestKvDevice < Test::Unit::TestCase

  def test_initalize_1
    d = KvDevice.new "DM", 0
    assert_equal "DM0", d.name
  end

  def test_initalize_without_suffix
    d = KvDevice.new "0"
    assert_equal "R00", d.name
  end

  def test_next_device_of_R0
    d = KvDevice.new "R0"
    assert_equal "R01", d.next_device.name
  end

  def test_next_device_of_R9
    d = KvDevice.new "R9"
    assert_equal "R10", d.next_device.name
  end

  def test_next_device_of_RF
    d = KvDevice.new "R15"
    assert_equal "R100", d.next_device.name
  end

  def test_add
    d = KvDevice.new "MR0"
    assert_equal "MR10", (d + 10).name
  end

  def test_sub
    d = KvDevice.new "MR100"
    assert_equal "MR06", (d - 10).name
  end

  def test_sub_case_below_zero
    d = KvDevice.new "MR100"
    assert_equal "MR00", (d - 101).name
  end

  def test_mr_device_is_bit_device
    d = KvDevice.new "MR0"
    assert_equal true, d.bit_device?
  end

end
