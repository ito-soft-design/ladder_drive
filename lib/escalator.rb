require "escalator/version"
require "escalator/cli"
require "escalator/asm"

Escalator_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module Escalator
end


Escalator::CLI.start