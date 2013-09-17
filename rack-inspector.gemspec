# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/inspector/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-inspector"
  spec.version       = Rack::Inspector::VERSION
  spec.authors       = ["Dan Sosedoff"]
  spec.email         = ["dan.sosedoff@gmail.com"]
  spec.description   = %q{Request inspection rack middleware}
  spec.summary       = %q{Request inspection rack middleware}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "redis"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler",   "~> 1.3"
  spec.add_development_dependency "rake",      "~> 10"
  spec.add_development_dependency "rspec",     "~> 2.13"
  spec.add_development_dependency "rack-test", "~> 0.6"
  spec.add_development_dependency "simplecov", "~> 0.7"
end
