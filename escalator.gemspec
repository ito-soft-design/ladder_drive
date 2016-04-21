# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'escalator/version'

Gem::Specification.new do |spec|
  spec.name          = "escalator"
  spec.version       = Escalator::VERSION
  spec.authors       = ["Katsuyoshi Ito"]
  spec.email         = ["kito@itosoft.com"]

  spec.summary       = %q{The escalator is a simple abstract ladder for PLC (Programmable Logic Controller).}
  spec.description   = %q{The escalator is a simple abstract ladder for PLC (Programmable Logic Controller). My aim is to design runnable abstraction ladder which is running on any PLC with same ladder source or binary and prepare full stack tools.}
  spec.homepage      = "https://github.com/ito-soft-design/escalator/wiki"
  spec.license       = "MIT"

  spec.add_dependency "thor"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
