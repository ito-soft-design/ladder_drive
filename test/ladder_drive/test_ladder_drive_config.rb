require 'test/unit'
require 'ladder_drive'

include LadderDrive

class TestLadderDriveConfigTarget < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_mc_protocol
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol" }
    config = LadderDriveConfigTarget.new h
    protocol = config.protocol
    assert_equal McProtocol, protocol.class
    assert_equal "192.168.0.10", protocol.host
    assert_equal 1234, protocol.port
  end

  def test_fins_tcp_protocol
    h = { host:"192.168.0.10", port:1234, protocol:"fins_tcp_protocol" }
    config = LadderDriveConfigTarget.new h
    protocol = config.protocol
    assert_equal FinsTcpProtocol, protocol.class
    assert_equal "192.168.0.10", protocol.host
    assert_equal 1234, protocol.port
  end

  def test_uploader
    config = LadderDriveConfigTarget.new
    assert_equal Uploader, config.uploader.class
  end

  def test_log_lebel
    h = { host:"192.168.0.10", port:1234, protocol:"mc_protocol", log_level:"debug" }
    config = LadderDriveConfigTarget.new h
    assert_equal :debug, config.protocol.log_level
  end

end


class TestLadderDriveConfig < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def test_default
    config = LadderDriveConfig.new
    assert_equal "build/main.hex", config.output
  end

  def test_emulator
    config = LadderDriveConfig.new
    expected = {:host=>"localhost", :keep=>[["L0", "L1023"], ["H0", "H1023"]], :port=>5555, :protocol=>"emu_protocol"}
    assert_equal expected, config[:plc][:emulator]
  end

  def test_default_target
    config = LadderDriveConfig.new
    assert_equal :emulator, config.target.name
  end

  def test_load
    dir = File.expand_path(File.dirname(__FILE__))
    path = File.join(dir, "files", "config.yml")
    config = LadderDriveConfig.load path
    t = config.target :plc
    assert_equal "192.168.1.2", t.host
    assert_equal 1234, t.port
  end

  def test_to_specify_default_target
    dir = File.expand_path(File.dirname(__FILE__))
    path = File.join(dir, "files", "config_with_default.yml")
    config = LadderDriveConfig.load path
    assert_equal :"iq-r", config.target.name
  end


end
