# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ladder_drive/version'

Gem::Specification.new do |spec|
  spec.name          = "ladder_drive"
  spec.version       = LadderDrive::VERSION
  spec.authors       = ["Katsuyoshi Ito"]
  spec.email         = ["kito@itosoft.com"]

  spec.summary       = %q{The ladder_drive is a simple abstract ladder for PLC (Programmable Logic Controller). Formerly known as 'escalator'.}
  spec.description   = %q{We aim to design abstraction ladder which is able to run on any PLC with same ladder source or binary and prepare full stack tools.}
  spec.homepage      = "https://github.com/ito-soft-design/ladder_drive"
  spec.license       = "MIT"

  spec.add_runtime_dependency 'thor', '~> 0'
  spec.add_runtime_dependency 'activesupport', '~> 4.2', '>= 4.2.7'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

end