require 'test/unit'
require 'escalator'

class TestMcProtoco < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def setup
    @protocol = McProtocol.new host:"localhost", port:5010#, log_level: :debug
    @protocol.open
  end

  def teardown
    @protocol.close
  end

=begin
  def test_open
    assert_not_nil @protocol.open
  end
=end

  def test_set_and_read_bool_value
    d = QDevice.new "M0"
    @protocol.set_bool_value(d, true)
    assert_equal true, @protocol.get_bool_value(d)
  end

  def test_set_and_read_word_value
    d = QDevice.new "D0"
    @protocol.set_word_value(d, 0x1234)
    assert_equal 0x1234, @protocol.get_word_value(d)
  end

end
