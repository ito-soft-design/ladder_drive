require 'test/unit'
require 'escalator'

class TestUploader < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def setup
    @hex_path = "/tmp/test.hex"
    hex = IntelHex.new (256..265).map{|v| [v].pack("n").unpack("c*")}.flatten
    hex.write_to @hex_path

    @protocol = McProtocol.new host:"localhost", port:5010, log_level: :debug
    @uploader = Uploader.new protocol:@protocol, program_area:"D10000"
    @uploader.source = @hex_path
  end

  def teardown
    FileUtils.rm @hex_path if File.exist? @hex_path
  end

  def test_dump
    assert_equal "D10000", @uploader.program_area
  end

  def test_word_data
    assert_equal (256..265).to_a, @uploader.word_data
  end

  def test_upload
    @uploader.upload
    assert_equal (256..265).to_a, @protocol.get_words_from_device(10, "D10000")
  end

end
