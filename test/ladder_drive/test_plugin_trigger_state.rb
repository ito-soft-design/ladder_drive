require 'test/unit'
require 'ladder_drive'

include LadderDrive::Emulator

class TestPluginTriggerState < Test::Unit::TestCase

  def setup
    @plc = EmuPlc.new
  end

  def test_changed_false
    config = {trigger:{device:"M100", type:"changed"}}
    state = PluginTriggerState.new @plc, config
    assert_equal(false, state.changed?)
    assert_equal(false, state.triggered?)
  end

  def test_changed_by_value
    config = {trigger:{device:"M100", type:"changed"}}
    state = PluginTriggerState.new @plc, config
    state.device.value = true
    state.update
    assert_equal(true, state.changed?)
    assert_equal(true, state.triggered?)
    state.reset
    state.update
    assert_equal(false, state.changed?)
    assert_equal(false, state.triggered?)
    state.reset
    state.device.value = false
    state.update
    assert_equal(true, state.changed?)
    assert_equal(true, state.triggered?)
  end

  def test_changed_by_bool
    config = {trigger:{device:"M100", type:"changed"}}
    state = PluginTriggerState.new @plc, config
    state.device.bool = true
    state.update
    assert_equal(true, state.changed?)
    assert_equal(true, state.triggered?)
    state.reset
    state.update
    assert_equal(false, state.changed?)
    assert_equal(false, state.triggered?)
    state.reset
    state.device.bool = false
    state.update
    assert_equal(true, state.changed?)
    assert_equal(true, state.triggered?)
  end

  def test_raised
    config = {trigger:{device:"M100", type:"raise"}}
    state = PluginTriggerState.new @plc, config
    state.device.bool = true
    state.update
    assert_equal(true, state.raised?)
    assert_equal(true, state.triggered?)
    state.reset
    state.update
    assert_equal(false, state.raised?)
    assert_equal(false, state.triggered?)
    state.reset
    state.device.bool = false
    state.update
    assert_equal(false, state.raised?)
    assert_equal(false, state.triggered?)
  end

  def test_fallen
    config = {trigger:{device:"M100", type:"fall"}}
    state = PluginTriggerState.new @plc, config
    state.device.bool = true
    state.update
    assert_equal(false, state.fallen?)
    assert_equal(false, state.triggered?)
    state.reset
    state.update
    assert_equal(false, state.fallen?)
    assert_equal(false, state.triggered?)
    state.reset
    state.device.bool = false
    state.update
    assert_equal(true, state.fallen?)
    assert_equal(true, state.triggered?)
  end

  def test_changed_with_value
    config = {trigger:{device:"D100", type:"changed"}}
    state = PluginTriggerState.new @plc, config
    state.device.value = 0
    state.update
    assert_equal(true, state.changed?)
    assert_equal(false, state.raised?)
    assert_equal(true, state.fallen?)
    state.reset
    state.update
    assert_equal(false, state.changed?)
    assert_equal(false, state.raised?)
    assert_equal(false, state.fallen?)
    state.reset
    state.device.value = 1
    state.update
    assert_equal(true, state.changed?)
    assert_equal(true, state.raised?)
    assert_equal(false, state.fallen?)
  end


end
