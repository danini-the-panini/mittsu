require 'mittsu/core/object_3d'
require 'mittsu/math/color'

module Mittsu
  class Light < Object3D
    attr_accessor :color, :only_shadow, :intensity, :distance

    def initialize(color = nil)
      super()
      @type = 'Light'
      @color = Color.new(color)
    end

    def clone(light = Light.new)
      super(light)

      light.color.copy(@color)
      light
    end
  end
end
