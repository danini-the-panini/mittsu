require 'mittsu/lights/light'

module Mittsu

  class HemisphereLight < Light
    attr_accessor :ground_color, :intensity

    def initialize(sky_color = nil, ground_color = nil, intensity = 1.0)
      super(sky_color)

      @type = 'HemisphereLight'

      @position.set(0.0, 100.0, 0.0)

      @ground_color = Color.new(ground_color)
      @intensity = intensity
    end

    def clone
      light = HemisphereLight.new
      super(light)

      light.ground_color.copy(@ground_color)
      light.intensity = @intensity

      light
    end
  end
end
