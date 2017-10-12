require 'test/unit'
require 'ladder_drive'

include LadderDrive

class TestMcProtocol < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def setup
    @protocol = McProtocol.new host:"10.0.1.201", port:5010, log_level: :debug
    timeout(0.5) do
      @running = !!@protocol.open
    end
  rescue Timeout::Error
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
    @protocol.set_words_to_device(values, d)
    assert_equal values, @protocol.get_words_from_device(values.size, d)
  end

  def test_convert_local_device_x0
    d = EscDevice.new "X0"
    ld = @protocol.device_by_name d
    assert_equal QDevice, ld.class
    assert_equal "X0", ld.name
  end

  def test_convert_local_device_prg0
    d = EscDevice.new "PRG0"
    ld = @protocol.device_by_name d
    assert_equal QDevice, ld.class
    assert_equal "D3072", ld.name
  end

  def test_convert_local_device_sd0
    d = EscDevice.new "SD0"
    ld = @protocol.device_by_name d
    assert_equal QDevice, ld.class
    assert_equal "D2048", ld.name
  end

  # array attr_accessor
  def test_set_and_get_bit_as_array
    omit_if(!@running)
    d = QDevice.new "M0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol[d, bits.size] = bits
    assert_equal bits, @protocol[d, bits.size]
  end

  def test_set_and_get_bit_as_array_with_range
    omit_if(!@running)
    d = QDevice.new "M0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol["M0".."M7"] = bits
    assert_equal bits, @protocol["M0".."M7"]
  end

  def test_set_and_get_bit_as_array_with_one
    omit_if(!@running)
    d = QDevice.new "M0"
    bits = "10010001".each_char.map{|c| c == "1"}
    @protocol["M0"] = true
    assert_equal true, @protocol["M0"]
  end

  def test_set_and_get_words_as_array
    omit_if(!@running)
    d = QDevice.new "D0"
    values = (256..265).to_a
    @protocol[d, values.size] = values
    assert_equal values, @protocol[d, values.size]
  end

  def test_set_and_get_words_as_array_with_range
    omit_if(!@running)
    d = QDevice.new "D0"
    values = (256..265).to_a
    @protocol["D0".."D9"] = values
    assert_equal values, @protocol["D0".."D9"]
  end

  def test_set_and_get_words_as_array_with_one
    omit_if(!@running)
    d = QDevice.new "D0"
    @protocol["D0"] = 123
    assert_equal 123, @protocol["D0"]
  end

end
