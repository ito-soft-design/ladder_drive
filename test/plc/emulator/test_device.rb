
require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), "../../helper"))
require 'emulator/emulator'

include Plc::Emulator

class TestDevice < Test::Unit::TestCase

  def test_device
    d = Device.new Device::X, 1234
    assert_equal Device::X, d.device_type
    assert_equal 1234, d.number
  end

  %w(X Y M - C T L SC CC TC D - CS TS H SD).each_with_index do |k, i|
    define_method :"test_#{k}" do
      assert_equal i, eval("Device::#{k}")
    end unless k == '-'
  end

end
