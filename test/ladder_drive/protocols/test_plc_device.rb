require 'test/unit'
require 'ladder_drive'

class TestPlcDevice < Test::Unit::TestCase
  include Protocol

  def test_sd0_should_not_be_bit_device
    d = PlcDevice.new "SD0"
    assert_equal false, d.bit_device?
  end

end
