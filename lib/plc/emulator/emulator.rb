dir = File.expand_path(File.dirname(__FILE__))
$:.unshift dir unless $:.include? dir

require 'emu_plc'
require 'emu_plc_server'
