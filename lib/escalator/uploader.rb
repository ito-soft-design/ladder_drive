module Escalator

  class Uploader

    attr_accessor :protocol
    attr_accessor :program_area
    attr_accessor :source
    attr_accessor :data

    def initialize options={}
      @protocol = options[:protocol]
      @program_area = options[:program_area]
    end

    def upload
      word_data.each_slice(2*1024) do |chunk|
        @protocol.set_words_to_device chunk, @program_area
      end
    end

    def data
      @data ||= begin
        hex = IntelHex.load @source
        hex.codes
      end
    end

    def word_data
      data.each_slice(2).map do |pair|
        pair.pack("c*").unpack("n*")
      end.flatten
    end

  end


end
