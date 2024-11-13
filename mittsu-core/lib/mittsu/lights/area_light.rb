require 'mittsu/lights/light'

module Mittsu
  class AreaLight < Light
    attr_accessor :normal, :right, :intensity, :width, :height, :constant_attenuation, :linear_attenuation, :quadratic_attenuation

    def initialize(color = nil, intensity = 1.0)
      super(color)
      @type = 'AreaLight'

      @normal = Vector3.new(0.0, -1.0, 0.0)
      @right = Vector3.new(1.0, 0.0, 0.0)

      @intensity = intensity

      @width = 1.0
      @height = 1.0

      @constant_attenuation = 1.5
      @linear_attenuation = 0.5
      @quadratic_attenuation = 0.1
    end
  end
end
