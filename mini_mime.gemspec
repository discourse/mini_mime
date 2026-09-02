# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) if !$LOAD_PATH.include?(lib)
require 'mini_mime/version'

Gem::Specification.new do |spec|
  spec.name          = "mini_mime"
  spec.version       = MiniMime::VERSION
  spec.authors       = ["Sam Saffron"]
  spec.email         = ["sam.saffron@gmail.com"]

  spec.summary       = %q{A minimal mime type library}
  spec.description   = %q{A minimal mime type library}
  spec.homepage      = "https://github.com/discourse/mini_mime"
  spec.license       = "MIT"

  spec.files = Dir["lib/**/*", "CHANGELOG", "LICENSE.txt", "README.md"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.3.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
