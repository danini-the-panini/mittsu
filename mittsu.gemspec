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
  spec.description   = %q{Mittsu makes 3D graphics easier by providing an abstraction over OpenGL, and is based heavily off of THREE.js. No more weird pointers and wondering about the difference between a VAO and a VBO (besides the letter). Simply think of something awesome and make it!}
  spec.homepage      = "https://github.com/danini-the-panini/mittsu"
  spec.license       = "MIT"
  spec.metadata = {
    "bug_tracker" => "https://github.com/danini-the-panini/mittsu/issues"
  }

  spec.required_ruby_version = '>= 2.0.0'
  spec.requirements << 'OpenGL 3.3+ capable hardware and drivers'

  spec.add_runtime_dependency 'mittsu-core', Mittsu::VERSION
  spec.add_runtime_dependency 'mittsu-renderer-opengl', Mittsu::VERSION
end
