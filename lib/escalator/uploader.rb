# The MIT License (MIT)
#
# Copyright (c) 2016 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
