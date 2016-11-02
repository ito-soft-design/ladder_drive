require 'test/unit'
require 'escalator'

include Escalator

class TestMcProtocol < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def setup
    @protocol = McProtocol.new host:"localhost", port:5010, log_level: :debug
    @running = !!@protocol.open
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
    omit_if(!@running)
    d = QDevice.new "M0"
    @protocol.set_bit_to_device(true, d)
    assert_equal true, @protocol.get_bit_from_device(d)
  end

  def test_set_and_read_word_value
    omit_if(!@running)
    d = QDevice.new "D0"
    @protocol.set_word_to_device(0x1234, d)
    assert_equal 0x1234, @protocol.get_word_from_device(d)
  end

  def test_set_and_read_bits
    omit_if(!@running)
    d = QDevice.new "M0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol.set_bits_to_device(bits, d)
    assert_equal bits, @protocol.get_bits_from_device(bits.size, d)
  end

  def test_set_and_read_words
    omit_if(!@running)
    d = QDevice.new "D0"
    values = (256..265).to_a
    @protocol.set_word_to_device(values, d)
    assert_equal values, @protocol.get_words_from_device(values.size, d)
  end

end
