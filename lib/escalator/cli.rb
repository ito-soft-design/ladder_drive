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

require 'thor'
require 'fileutils'

include FileUtils

module LadderDrive
  class CLI < Thor

    desc "create", "Create a new project"
    def create(name)
      if File.exist? name
        puts "ERROR: #{name} already exists."
        exit -1
      end

      # copy from template file
      root_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
      template_path = File.join(root_dir, "template", "escalator")
      cp_r template_path, name

      # copy plc directory
      temlate_plc_path = File.join(root_dir, "lib", "plc")
      cp_r temlate_plc_path, name
      # remove unnecessary file from plc directory
      %w(plc.rb emulator).each do |fn|
        rm_r File.join(name, "plc", fn)
      end
      puts "#{name} was successfully created."
    end

  end
end
