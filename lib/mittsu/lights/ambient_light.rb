require 'mittsu/lights/light'

module Mittsu
  class AmbientLight < Light
    def initialize(color)
      super
      @type = 'AmbientLight'
    end

    def clone
      light = AmbientLight.new
      super(light)
      light
    end
  end
end
