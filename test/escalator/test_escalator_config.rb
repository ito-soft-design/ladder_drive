require 'test/unit'
require 'escalator'

include Escalator

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

  def test_program_area
    h = { plc: { host:"192.168.0.10", port:1234, protocol:"mc_protocol", program_area:"D10000" } }
    config = EscalatorConfig.new h
    uploader = config.uploader
    assert_equal Uploader, uploader.class
    assert_not_nil uploader.protocol, uploader.class
    assert_equal "D10000", uploader.program_area.name
  end

  def test_default
    config = EscalatorConfig.new
    assert_equal "build/main.hex", config.output
  end

  def test_uploader
    config = EscalatorConfig.new
    assert_equal Uploader, config.uploader.class
  end

  def test_log_lebel
    h = { plc: { host:"192.168.0.10", port:1234, protocol:"mc_protocol", program_area:"D10000", log_level:"debug" } }
    config = EscalatorConfig.new h
    assert_equal :debug, config.protocol.log_level
  end

end
