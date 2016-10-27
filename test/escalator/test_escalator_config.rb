require 'test/unit'
require 'escalator'

class TestEscalatorConfig < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_mc_protocol
    config = EscalatorConfig.new ip:"192.168.0.10", port:5010, protocol:"mc_protocol"
    protocol = config.protocol
    assert_equal McProtocol, protocol.class
    assert_equal "192.168.0.10", protocol.ip
  end

end
