$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest'
require 'mittsu'
Dir[__dir__ + '/support/*.rb'].each {|file| require file }

require 'minitest/autorun'
