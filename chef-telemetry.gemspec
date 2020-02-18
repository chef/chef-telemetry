# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef/telemetry/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-telemetry"
  spec.version       = Chef::Telemetry::VERSION
  spec.authors       = ["Chef Software, Inc."]
  spec.email         = "info@chef.io"
  spec.homepage      = "https://github.com/chef/chef-telemetry"
  spec.license       = "Apache-2.0"
  spec.summary       = %q{Send user actions to the Chef telemetry system. See Chef RFC-051 for further information}
  spec.files         = %w{LICENSE} + Dir.glob("lib/**/*")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_dependency "http", "~> 4"
  spec.add_dependency "ffi-yajl", "~> 2.2"
  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "chef-config"
end
