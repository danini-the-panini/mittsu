# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mittsu/version'

Gem::Specification.new do |spec|
  spec.name          = "mittsu"
  spec.version       = Mittsu::VERSION
  spec.authors       = ["Daniel Smith"]
  spec.email         = ["jellymann@gmail.com"]

  spec.summary       = %q{3D Graphics Library for Ruby}
  spec.description   = %q{Mittsu makes 3D graphics easier by providing an abstraction over OpenGL, and is based heavily off of THREE.js. No more weird pointers and wondering about the difference between a VAO and a VBO (besides the letter). Simply think of something awesome and make it!}
  spec.homepage      = "https://github.com/jellymann/mittsu"
  spec.license       = "MIT"
  spec.metadata = {
    "bug_tracker" => "https://github.com/jellymann/mittsu/issues"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{(^(test|examples)/|\.sh$)}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'
  spec.requirements << 'OpenGL 3.3+ capable hardware and drivers'

  spec.add_runtime_dependency 'opengl-bindings', "~> 1.5"
  spec.add_runtime_dependency 'ffi', "~> 1.9"
  spec.add_runtime_dependency 'chunky_png', "~> 1.3"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest', '~> 5.7'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'benchmark-ips', '~> 2.3'
  spec.add_development_dependency 'simplecov', '~> 0.17'
end
