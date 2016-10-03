require 'test/unit'
require 'escalator'

class TestIntelHex < Test::Unit::TestCase

  def test_dump
    codes = (0...16).to_a
    hex = Escalator::IntelHex.new codes
    expected = <<EOB
:10000000000102030405060708090a0b0c0d0e0f78
:00000001FF
EOB
    assert_equal expected, hex.dump

    source = StringIO.new <<EOB
NOP
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x07], asm.codes
  end

  def test_dump_2_lines
    codes = (0..16).to_a
    hex = Escalator::IntelHex.new codes
    expected = <<EOB
:10000000000102030405060708090a0b0c0d0e0f78
:0100100010df
:00000001FF
EOB
    assert_equal expected, hex.dump

    source = StringIO.new <<EOB
NOP
EOB
    asm = Escalator::Asm.new source
    assert_equal [0x07], asm.codes
  end

  def test_gxworks_memory_image
    codes = (0...16).to_a
    hex = Escalator::IntelHex.new codes
    expected = "0\t1\t2\t3\t4\t5\t6\t7\n8\t9\t10\t11\t12\t13\t14\t15"
    assert_equal expected, hex.gxworks_memory_image
  end

end
