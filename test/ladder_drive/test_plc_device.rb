require 'test/unit'
require 'ladder_drive'

class TestPlcDevice < Test::Unit::TestCase

  def test_x9_s_next_device_is_xa
    d = PlcDevice.new "X9"
    assert_equal "X0A", (d + 1).name
  end

  def test_to_get_name_of_hex_type_device
    d = PlcDevice.new "x0a"
    assert_equal "X0A", d.name
  end

  def test_value_from_true
    d = PlcDevice.new "x0a"
    d.value = true
    assert_equal 1, d.value
  end

  def test_value_from_false
    d = PlcDevice.new "x0a"
    d.value = false
    assert_equal 0, d.value
  end

  def test_value_from_nil
    d = PlcDevice.new "x0a"
    d.value = nil
    assert_equal 0, d.value
  end

end
