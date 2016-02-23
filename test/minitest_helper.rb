require 'codeclimate-test-reporter'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  Coveralls::SimpleCov::Formatter,
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
]
SimpleCov.start

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
