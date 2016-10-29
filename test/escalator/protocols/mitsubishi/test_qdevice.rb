require 'test/unit'
require 'escalator'

class TestQDevice < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_initalize_1
    d = QDevice.new "D", 0
    assert_equal "D0", d.name
  end

  def test_initalize_2
    d = QDevice.new [3, 2, 1, 0xa8]
    assert_equal "D#{65536+2*256+3}", d.name
  end

  def test_next_device_of_X0
    d = QDevice.new "X0"
    assert_equal "X1", d.next_device.name
  end

  def test_next_device_of_X9
    d = QDevice.new "X9"
    assert_equal "XA", d.next_device.name
  end

  def test_next_device_of_XF
    d = QDevice.new "XF"
    assert_equal "X10", d.next_device.name
  end

  def test_suffix_code
    d = QDevice.new "M0"
    assert_equal 0x90, d.suffix_code
  end

  def test_add
    d = QDevice.new "M0"
    assert_equal "M100", (d + 100).name
  end

  def test_sub
    d = QDevice.new "M100"
    assert_equal "M85", (d - 15).name
  end

  def test_sub_case_below_zero
    d = QDevice.new "M100"
    assert_equal "M0", (d - 101).name
  end

end
