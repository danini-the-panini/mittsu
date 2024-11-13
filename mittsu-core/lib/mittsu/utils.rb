module Mittsu
  DEBUG = ENV["DEBUG"] == "true"

  def self.debug?
    DEBUG
  end

  def self.env
    ENV["MITTSU_ENV"]
  end

  def self.test?
    env == 'test'
  end
end