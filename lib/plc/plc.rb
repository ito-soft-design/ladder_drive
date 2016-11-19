dir = File.expand_path(File.dirname(__FILE__))
$:.unshift dir unless $:.include? dir

# Use load instead require, because there are two emulator files.
load File.join(dir, 'emulator/emulator.rb')
