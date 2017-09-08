# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "telemetry/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-telemetry"
  spec.version       = Telemetry::VERSION

  spec.email = "info@chef.io"
  spec.homepage = "https://www.chef.io"
  spec.license = "Apache-2.0"
  spec.authors = ["Chef Software, Inc."]
  spec.summary       = %q{Send user actions to the Chef telemetry system. See RFC-xxx for further information}

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 11.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "http", "~> 2.2"
  spec.add_dependency "ffi-yajl", "~> 2.2"
  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "chef-config"
end
