require 'test/unit/rr'

class TestFinsTcpProtocolOnOffline < Test::Unit::TestCase
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
    omit_if(@running)
    packet = [ "FINS".bytes.to_a,  0, 0, 0, 0x10,  0, 0, 0, 1,  0, 0, 0, 0,  0, 0, 0, 1,  0, 0, 0, 2].flatten
    stub(@protocol).receive{ packet }
    stub(@protocol).send_packet
    @protocol.query_node
    assert_equal 2, @protocol.source_node
  end

end
