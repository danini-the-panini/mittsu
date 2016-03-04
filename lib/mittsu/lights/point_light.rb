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

    protected

    def jsonify
      data = super
      data[:color] = self.color.get_hex
      data[:intensity] = self.intensity
      data[:distance] = self.distance
      data[:decay] = self.decay
      data
    end
  end
end
