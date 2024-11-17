# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mittsu/version'

Gem::Specification.new do |spec|
  spec.name          = "mittsu"
  spec.version       = Mittsu::VERSION
  spec.authors       = ["Danielle Smith"]
  spec.email         = ["danini@hey.com"]

  spec.summary       = %q{3D Graphics Library for Ruby}
  spec.description   = %q{Mittsu is a 3D Graphics Library for Ruby, based heavily on Three.js}
  spec.homepage      = "https://github.com/danini-the-panini/mittsu"
  spec.license       = "MIT"
  spec.metadata = {
    "bug_tracker" => "https://github.com/danini-the-panini/mittsu/issues"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{(^(test)/|\.sh$)}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_runtime_dependency 'chunky_png'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'simplecov', '0.17.1'
end
