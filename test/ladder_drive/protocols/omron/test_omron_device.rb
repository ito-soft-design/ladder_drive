require 'test/unit'
require 'ladder_drive'

class TestOmronDevice < Test::Unit::TestCase
  include Protocol::Omron

  def test_initalize_1
    d = OmronDevice.new "D", 0
    assert_equal "D0", d.name
  end

  def test_initalize_2
    d = OmronDevice.new "M", 1
    assert_equal "M1", d.name
  end

  def test_initalize_3
    d = OmronDevice.new "M", 1, 2
    assert_equal "M1.02", d.name
  end

  def test_m0_0_is_bit_device
    d = OmronDevice.new "M0.0"
    assert_true d.bit_device?
  end

  def test_m0_is_bit_device
    d = OmronDevice.new "M0"
    assert_false d.bit_device?
  end

  def test_0_0_is_bit_device
    d = OmronDevice.new "0.0"
    assert_true d.bit_device?
  end

  def test_0_is_bit_device
    d = OmronDevice.new "0"
    assert_false d.bit_device?
  end

  def test_D0_0_is_bit_device
    d = OmronDevice.new "D0.0"
    assert_true d.bit_device?
  end

  def test_D0_is_bit_device
    d = OmronDevice.new "D0"
    assert_false d.bit_device?
  end

  def test_add_16_to_0_0
    d = OmronDevice.new "0.1"
    d = d + 16
    assert_equal "1.01", d.name
  end

  def test_sub_16_from_1_1
    d = OmronDevice.new "1.01"
    d = d - 16
    assert_equal "0.01", d.name
  end

  def test_sub_20_from_1_1
    d = OmronDevice.new "1.01"
    d = d - 20
    assert_equal "0.00", d.name
  end

  def test_sub_from_device
    assert_equal 18, OmronDevice.new("2.01") - OmronDevice.new("0.15")
  end


  def test_availability_for_channel_device_as_channel
    d = OmronDevice.new "10"
    assert_equal "10", d.name
  end

  def test_availability_for_channel_device_as_bit
    d = OmronDevice.new "10.1"
    assert_equal "10.01", d.name
  end

  def test_availability_for_m_device_as_channel
    d = OmronDevice.new "m10"
    assert_equal "M10", d.name
  end

  def test_availability_for_m_device_as_bit
    d = OmronDevice.new "m10.1"
    assert_equal "M10.01", d.name
  end

  def test_availability_for_h_device_as_channel
    d = OmronDevice.new "h10"
    assert_equal "H10", d.name
  end

  def test_availability_for_h_device_as_bit
    d = OmronDevice.new "h10.1"
    assert_equal "H10.01", d.name
  end

  def test_availability_for_d_device_as_channel
    d = OmronDevice.new "d10"
    assert_equal "D10", d.name
  end

  def test_availability_for_d_device_as_bit
    d = OmronDevice.new "d10.1"
    assert_equal "D10.01", d.name
  end

  def test_availability_for_t_device
    d = OmronDevice.new "t10"
    assert_equal "T10", d.name
  end

  def test_availability_for_t_device_as_bit
    assert_raise(RuntimeError) {
      d = OmronDevice.new "t10.0"
    }
  end

  def test_availability_for_c_device
    d = OmronDevice.new "c10"
    assert_equal "C10", d.name
  end

  def test_availability_for_c_device_as_bit
    assert_raise(RuntimeError) {
      d = OmronDevice.new "c10.0"
    }
  end

  def test_availability_for_a_device_as_channel
    d = OmronDevice.new "a10"
    assert_equal "A10", d.name
  end

  def test_availability_for_a_device_as_bit
    d = OmronDevice.new "a10.1"
    assert_equal "A10.01", d.name
  end


  def test_channel_device_for_0_0
    d = OmronDevice.new "0.0"
    assert_equal "0", d.channel_device.name
  end


end
