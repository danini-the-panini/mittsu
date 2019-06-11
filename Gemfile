source 'https://rubygems.org'

gemspec

gem "codeclimate-test-reporter", group: :test, require: false
gem 'coveralls', group: :test, require: false

if /darwin/ === RUBY_PLATFORM
  gem 'ffi', '~> 1.9', '!= 1.11.1'
end
