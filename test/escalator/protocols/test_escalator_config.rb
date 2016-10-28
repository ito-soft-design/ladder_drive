require 'test/unit'
require 'escalator'

class TestEscalatorConfig < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_mc_protocol
    h = { plc: { host:"192.168.0.10", port:1234, protocol:"mc_protocol" } }
    config = EscalatorConfig.new h
    protocol = config.protocol
    assert_equal McProtocol, protocol.class
    assert_equal "192.168.0.10", protocol.host
    assert_equal 1234, protocol.port
  end

  def test_default
    config = EscalatorConfig.new
    assert_equal "build/main.hex", config.output
  end

end
