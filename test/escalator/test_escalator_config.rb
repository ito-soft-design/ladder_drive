require 'test/unit'
require 'escalator'

include Escalator

class TestEscalatorConfigTarget < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_mc_protocol
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol" }
    config = EscalatorConfigTarget.new h
    protocol = config.protocol
    assert_equal McProtocol, protocol.class
    assert_equal "192.168.0.10", protocol.host
    assert_equal 1234, protocol.port
  end

  def test_program_area
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol", program_area:"D10000" }
    config = EscalatorConfigTarget.new h
    uploader = config.uploader
    assert_equal Uploader, uploader.class
    assert_not_nil uploader.protocol, uploader.class
    assert_equal "D10000", uploader.program_area.name
  end

  def test_interaction_area
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol", program_area:"D10000", interaction_area:"D9998" }
    config = EscalatorConfigTarget.new h
    uploader = config.uploader
    assert_equal "D9998", uploader.interaction_area.name
  end

  def test_uploader
    config = EscalatorConfigTarget.new
    assert_equal Uploader, config.uploader.class
  end

  def test_log_lebel
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol", program_area:"D10000", log_level:"debug" }
    config = EscalatorConfigTarget.new h
    assert_equal :debug, config.protocol.log_level
  end

end


class TestEscalatorConfig < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_default
    config = EscalatorConfig.new
    assert_equal "build/main.hex", config.output
  end

  def test_emulator
    config = EscalatorConfig.new
    expected = { host:"localhost", port:5555 }
    assert_equal expected, config[:emulator]
  end

  def test_default_target
    config = EscalatorConfig.new
    assert_equal :emulator, config.target.name
  end

  def test_load
    dir = File.expand_path(File.dirname(__FILE__))
    path = File.join(dir, "files", "config.yml")
    config = EscalatorConfig.load path
    t = config.target :plc
    assert_equal "192.168.1.2", t.host
    assert_equal 1234, t.port
  end


end
