require 'test/unit/rr'
require 'test/unit/notify'

class TestCModeProtocol < Test::Unit::TestCase
  include Protocol::Omron

  attr_reader :running

  def setup
    @protocol = CModeProtocol.new log_level: :debug
    Timeout.timeout(0.5) do
      @running = !!@protocol.open
    end
  rescue Timeout::Error
  end

  def teardown
    #@protocol.set_bits_to_device([false] * 8, FxDevice.new("M3000")) if @running
    @protocol.close
  end

=begin
  def test_get_word_from_device_with_1_2_with_stub
    stub(@protocol).receive{ "@00RR00123444*\r" }
    stub(@protocol).send
    assert_equal 0x1234, @protocol.get_word_from_device('1.2')
  end

  def test_get_bit_from_device_with_1_2
    stub(@protocol).receive{ "@00RR00123444*\r" }
    stub(@protocol).send

    assert_equal false, @protocol.get_bit_from_device('1.0')
    assert_equal false, @protocol.get_bit_from_device('1.1')
    assert_equal true,  @protocol.get_bit_from_device('1.2')
    assert_equal false, @protocol.get_bit_from_device('1.3')

    assert_equal true,  @protocol.get_bit_from_device('1.4')
    assert_equal true,  @protocol.get_bit_from_device('1.5')
    assert_equal false, @protocol.get_bit_from_device('1.6')
    assert_equal false, @protocol.get_bit_from_device('1.7')

    assert_equal false, @protocol.get_bit_from_device('1.8')
    assert_equal true,  @protocol.get_bit_from_device('1.9')
    assert_equal false, @protocol.get_bit_from_device('1.10')
    assert_equal false, @protocol.get_bit_from_device('1.11')

    assert_equal true,  @protocol.get_bit_from_device('1.12')
    assert_equal false, @protocol.get_bit_from_device('1.13')
    assert_equal false, @protocol.get_bit_from_device('1.14')
    assert_equal false, @protocol.get_bit_from_device('1.15')
  end
=end

#=begin
  def test_get_word_from_device_with_1_2
    assert_equal 0, @protocol.get_word_from_device('1.2')
  end

  def test_get_word_from_device_with_D1000
    assert_equal 0, @protocol.get_word_from_device('D1000')
  end
#=end

end
