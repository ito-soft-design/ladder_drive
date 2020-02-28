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

  spec.add_runtime_dependency 'thor',           '~> 0'
  spec.add_runtime_dependency 'activesupport',  '~> 4.0'
  spec.add_runtime_dependency 'ffi',            '~> 1.9', '>= 1.9.24'
  spec.add_runtime_dependency 'pi_piper',       '~> 2.0', '>= 2.0.0'

  spec.add_runtime_dependency 'serialport',     '~> 1.3', '>= 1.3.1'
  spec.add_runtime_dependency 'ambient_iot',    '~> 0.1', '>= 0.1.1'
  spec.add_runtime_dependency 'google_drive',   '~> 3.0', '>= 3.0.3'
  spec.add_runtime_dependency 'ruby-trello',    '~>2.1'
  spec.add_runtime_dependency 'dotenv',    '~>2.1'

  spec.required_ruby_version = '>= 2.3.3'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 13.0"

end
