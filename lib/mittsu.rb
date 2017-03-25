require "mittsu/utils"
require "mittsu/jruby_shim"

module Mittsu
  DEBUG = ENV["DEBUG"] == "true"

  def self.debug?
    DEBUG
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
