require 'test/unit'
require 'ladder_drive'

class TestUploader < Test::Unit::TestCase
  include Protocol::Mitsubishi

  def setup
    @hex_path = "/tmp/test.hex"
    hex = IntelHex.new (256..265).map{|v| [v].pack("n").unpack("c*")}.flatten
    hex.write_to @hex_path

    @protocol = McProtocol.new host:"localhost", port:5010, log_level: :debug
    @uploader = Uploader.new protocol:@protocol
    @uploader.source = @hex_path
    @running = !!@protocol.open
  end

  def teardown
    FileUtils.rm @hex_path if File.exist? @hex_path
  end

  def test_word_data
    omit_if(!@running)
    assert_equal (256..265).to_a, @uploader.word_data
  end

  def test_upload
    omit_if(!@running)
    @uploader.upload
    assert_equal (256..265).to_a, @protocol.get_words_from_device(10, "D10000")
  end

end
