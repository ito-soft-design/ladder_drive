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

Escalator_root = File.expand_path(File.join(File.dirname(__FILE__), "../../../"))

require "escalator/config"
require 'escalator/asm'
require 'escalator/intel_hex'
require 'rake/loaders/makefile'
require 'fileutils'

#directory "build"

directory "build"

desc "Assemble codes"
rule %r{^build/.+\.lst} => ['%{^build,asm}X.esc'] do |t|
  Rake::Task["build"].invoke
  begin
    $stderr = File.open('hb.log', 'w')
    $stdout = $stderr
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
  #dir = "./asm"
  stream = StringIO.new
  #filename = "asm/#{t.source}"
  puts "asm #{t.source}"
  asm = Escalator::Asm.new File.read(t.source)
  #dst = File.join("build", t.name)
  File.write(t.name, asm.dump_line)
end

desc "Make hex codes"
rule %r{^build/.+\.hex} => ['%{^build,asm}X.esc'] do |t|
  Rake::Task["build"].invoke
  begin
    $stderr = File.open('hb.log', 'w')
    $stdout = $stderr
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
  stream = StringIO.new
  puts "hex #{t.source}"
  asm = Escalator::Asm.new File.read(t.source)
  hex = Escalator::IntelHex.new asm.codes
  File.write(t.name, hex.dump)
end

desc "Clean all generated files."
task :clean do
  FileUtils.rm_r "build"
end

@config = Escalator::EscalatorConfig.default

task :upload => @config.output do
  t = @config.target ENV['target']
  u = t.uploader
  u.source = @config.output
  u.upload
  puts "upload #{u.source}"
end

desc "Install program to PLCs."
task :plc => :upload do
end

task :default => :plc
