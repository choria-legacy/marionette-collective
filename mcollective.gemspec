# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mcollective'

Gem::Specification.new do |spec|
  spec.name          = "mcollective"
  spec.version       = MCollective.version
  spec.authors       = ["Puppet Labs"]
  spec.email         = ["info@puppetlabs.com"]
  spec.summary       = %q{Marionette Collective}
  spec.description   = %q{The Marionette Collective aka. mcollective is a framework to build server orchestration or parallel job execution systems.}
  spec.homepage      = "https://github.com/puppetlabs/marionette-collective"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "json"
  spec.add_dependency "stomp", ">= 1.4.1"
  spec.add_dependency "systemu"
end
