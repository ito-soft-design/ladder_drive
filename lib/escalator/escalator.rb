dir = File.expand_path(File.dirname(__FILE__))
$:.unshift dir unless $:.include? dir

module Escalator
end

require "version"
require "cli"
require "asm"
require "intel_hex"
require "plc_define"
require "uploader"
require "config"
require "config_target"
require "plc_device"
require "protocol/protocol"
require "console"
