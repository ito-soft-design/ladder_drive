require 'test/unit/rr'

class TestFinsTcpProtocol < Test::Unit::TestCase
  include Protocol::Omron

  def setup
    @protocol = FinsTcpProtocol.new host:'localhost', log_level: :debug
    Timeout.timeout(0.5) do
      @running = !!@protocol.open
    end
  rescue Timeout::Error
  end

  def teardown
    #@protocol.set_bits_to_device([false] * 8, FxDevice.new("M3000")) if @running
    @protocol.close
  end

  def test_query_node
    omit_if(!@running)
    # query node at opening
    assert_equal 239, @protocol.source_node
  end

  def test_get_words_from_device
    omit_if(!@running)
    assert_equal [0, 0, 0, 0, 0], @protocol.get_words_from_device(5, "D0")
  end

  def test_get_bits_from_device
    omit_if(!@running)
    assert_equal [false, false, false, false, false], @protocol.get_bits_from_device(5, "1.1")
  end

  def test_set_bits_to_device
    omit_if(!@running)
    @protocol.set_bits_to_device([false, true, true, false], "2.0")
    assert_equal [false, true, true, false], @protocol.get_bits_from_device(4, "2.0")
  end

  def test_set_words_to_device
    omit_if(!@running)
    @protocol.set_words_to_device([0x1, 0x12, 0x123, 0x1234, 0x2345], "D10")
    assert_equal [0x1, 0x12, 0x123, 0x1234, 0x2345], @protocol.get_words_from_device(5, "D10")
  end

  def test_set_bit_to_device
    omit_if(!@running)
    @protocol.set_bit_to_device(true, "2.0")
    assert_equal true, @protocol.get_bit_from_device("2.0")
  end

  def test_set_word_to_device
    omit_if(!@running)
    @protocol.set_word_to_device(0x2345, "D10")
    assert_equal 0x2345, @protocol.get_word_from_device("D10")
  end




  # availble bits/words range

  def test_available_bits_range_for_etn21
    #@protocol.ethernet_module = FinsTcpProtocol::ETHERNET_ETN21
    assert_equal 1..2004, @protocol.available_bits_range
  end

  def test_available_words_range_for_etn21
    #@protocol.ethernet_module = FinsTcpProtocol::ETHERNET_ETN21
    assert_equal 1..1002, @protocol.available_words_range
  end

  def test_available_bits_range_for_cp1e
    @protocol.ethernet_module = FinsTcpProtocol::ETHERNET_CP1E
    assert_equal 1..532, @protocol.available_bits_range
  end

  def test_available_words_range_for_cp1e
    @protocol.ethernet_module = FinsTcpProtocol::ETHERNET_CP1E
    assert_equal 1..266, @protocol.available_words_range
  end

  def test_available_bits_range_for_cp1l
    @protocol.ethernet_module = FinsTcpProtocol::ETHERNET_CP1L
    assert_equal 1..996, @protocol.available_bits_range
  end

  def test_available_words_range_for_cp1l
    @protocol.ethernet_module = FinsTcpProtocol::ETHERNET_CP1L
    assert_equal 1..498, @protocol.available_words_range
  end

end
