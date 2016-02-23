require 'codeclimate-test-reporter'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  Coveralls::SimpleCov::Formatter,
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
]
SimpleCov.start do
  add_filter "/test/"
  add_group 'Cameras', 'lib/mittsu/cameras'
  add_group 'Core', 'lib/mittsu/core'
  add_group 'Extras', 'lib/mittsu/extras'
  add_group 'Lights', 'lib/mittsu/lights'
  add_group 'Loaders', 'lib/mittsu/loaders'
  add_group 'Materials', 'lib/mittsu/materials'
  add_group 'Math', 'lib/mittsu/math'
  add_group 'Objects', 'lib/mittsu/objects'
  add_group 'Renderers', 'lib/mittsu/renderers'
  add_group 'Scenes', 'lib/mittsu/scenes'
  add_group 'Textures', 'lib/mittsu/textures'
end

require "minitest/reporters"
REPORTER = "#{ENV['MINITEST_REPORTER'] || 'Progress'}Reporter"
if !Minitest::Reporters.const_defined?(REPORTER)
  puts "WARNING: Reporter \"#{REPORTER}\" not found, using default"
  Minitest::Reporters.use!
else
  Minitest::Reporters.use! Minitest::Reporters.const_get(REPORTER).new
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest'
require 'mittsu'
Dir[__dir__ + '/support/*.rb'].each {|file| require file }

require 'minitest/autorun'
