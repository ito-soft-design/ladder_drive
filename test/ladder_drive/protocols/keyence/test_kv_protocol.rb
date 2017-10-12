require 'test/unit'
require 'ladder_drive'

include LadderDrive:: Protocol::Keyence

class TestKvProtocol < Test::Unit::TestCase

  def setup
    @protocol = KvProtocol.new host:"10.0.1.200", log_level: :debug
    timeout(0.5) do
      @running = !!@protocol.open
    end
  rescue Timeout::Error
  end

  def teardown
    @protocol.close
  end

  def test_set_and_read_bool_value
    omit_if(!@running)
    d = KvDevice.new "MR0"
    @protocol.set_bit_to_device(true, d)
    assert_equal true, @protocol.get_bit_from_device(d)
  end

  def test_set_and_read_word_value
    omit_if(!@running)
    d = KvDevice.new "DM0"
    @protocol.set_word_to_device(0x1234, d)
    assert_equal 0x1234, @protocol.get_word_from_device(d)
  end

  def test_set_and_read_bits
    omit_if(!@running)
    d = KvDevice.new "MR0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol.set_bits_to_device(bits, d)
    assert_equal bits, @protocol.get_bits_from_device(bits.size, d)
  end

  def test_set_and_read_words
    omit_if(!@running)
    d = KvDevice.new "DM0"
    values = (256..265).to_a
    @protocol.set_word_to_device(values, d)
    assert_equal values, @protocol.get_words_from_device(values.size, d)
  end

  # array attr_accessor
  def test_set_and_get_bit_as_array
    omit_if(!@running)
    d = KvDevice.new "MR0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol[d, bits.size] = bits
    assert_equal bits, @protocol[d, bits.size]
  end

  def test_set_and_get_bit_as_array_with_range
    omit_if(!@running)
    d = KvDevice.new "MR0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol["MR0".."MR7"] = bits
    assert_equal bits, @protocol["MR0".."MR7"]
  end

  def test_set_and_get_bit_as_array_with_one
    omit_if(!@running)
    d = KvDevice.new "MR0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol["MR0"] = true
    assert_equal true, @protocol["MR0"]
  end

  def test_set_and_get_words_as_array
    omit_if(!@running)
    d = KvDevice.new "DM0"
    values = (256..265).to_a
    @protocol[d, values.size] = values
    assert_equal values, @protocol[d, values.size]
  end

  def test_set_and_get_words_as_array_with_range
    omit_if(!@running)
    d = KvDevice.new "DM0"
    values = (256..265).to_a
    @protocol["DM0".."DM9"] = values
    assert_equal values, @protocol["DM0".."DM9"]
  end

  def test_set_and_get_words_as_array_with_one
    omit_if(!@running)
    d = KvDevice.new "DM0"
    @protocol["DM0"] = 123
    assert_equal 123, @protocol["DM0"]
  end


end
