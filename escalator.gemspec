# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'escalator/version'

Gem::Specification.new do |spec|
  spec.name          = "escalator"
  spec.version       = LadderDrive::VERSION
  spec.authors       = ["Katsuyoshi Ito"]
  spec.email         = ["kito@itosoft.com"]

  spec.summary       = %q{The escalator is a simple abstract ladder for PLC (Programmable Logic Controller).}
  spec.description   = %q{We aim to design abstraction ladder which is able to run on any PLC with same ladder source or binary and prepare full stack tools.}
  spec.homepage      = "https://github.com/ito-soft-design/escalator"
  spec.license       = "MIT"

  spec.add_dependency "thor"
  spec.add_runtime_dependency "activesupport", ">=4.2.7"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.post_install_message = <<-MESSAGE
   ! The 'escalator' gem has been deprecated and has been replaced by 'ladder_drive'.
   ! See: https://rubygems.org/gems/ladder_drive
   ! And: https://github.com/ito-soft-design/ladder_drive
  MESSAGE
end
