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

require "mittsu/version"
require "mittsu/math"
require "mittsu/core"
require "mittsu/cameras"
require "mittsu/extras"
require "mittsu/lights"
require "mittsu/loaders"
require "mittsu/materials"
require "mittsu/objects"
require "mittsu/renderers"
require "mittsu/scenes"
require "mittsu/textures"
require "mittsu/constants"
