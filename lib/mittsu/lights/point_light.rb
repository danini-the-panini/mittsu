require 'mittsu/lights/light'

module Mittsu
  class PointLight < Light
    attr_accessor :decay

    def initialize(color = nil, intensity = 1.0, distance = 0.0, decay = 1.0)
      super(color)

      @type = 'PointLight'

      @intensity = intensity
      @distance = distance
      @decay = decay # for physically correct light, should be 2
    end

    def clone
      light = PointLight.new
      super(light)

      light.intensity = @intensity
      light.distance = @distance
      light.decay = @decay
      light
    end
  end
end
