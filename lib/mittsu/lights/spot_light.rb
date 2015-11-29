require 'mittsu/lights/light'

module Mittsu
  class SpotLight < Light
    attr_accessor :target,
                  :angle,
                  :exponent,
                  :decay,
                  :cast_shadow,
                  :shadow_camera_near,
                  :shadow_camera_far,
                  :shadow_camera_fov,
                  :shadow_camera_visible,
                  :shadow_bias,
                  :shadow_darkness,
                  :shadow_map_width,
                  :shadow_map_height,
                  :shadow_map,
                  :shadow_map_size,
                  :shadow_camera,
                  :shadow_matrix

    def initialize(color = nil, intensity = 1.0, distance = 0.0, angle = (Math::PI / 3.0), exponent = 10.0, decay = 1.0)
      super(color)

      @type = 'SpotLight'

      @position.set( 0, 1, 0 )
      @target = Object3D.new

      @intensity = intensity
      @distance = distance
      @angle = angle
      @exponent = exponent
      @decay = decay # for physically correct lights, should be 2.

      @cast_shadow = false
      @only_shadow = false

      #

      @shadow_camera_near = 50.0
      @shadow_camera_far = 5000.0
      @shadow_camera_fov = 50.0

      @shadow_camera_visible = false

      @shadow_bias = 0
      @shadow_darkness = 0.5

      @shadow_map_width = 512
      @shadow_map_height = 512

      #

      @shadow_map = nil
      @shadow_map_size = nil
      @shadow_camera = nil
      @shadow_matrix = nil
    end

    def virtual?
      @is_virtual
    end

    def is_virtual=(value)
      @is_virtual = value
    end

    def clone

      light = SpotLight.new

      super(light)

      light.target = @target.clone

      light.intensity = @intensity
      light.distance = @distance
      light.angle = @angle
      light.exponent = @exponent
      light.decay = @decay

      light.cast_shadow = @cast_shadow
      light.only_shadow = @only_shadow

      #

      light.shadow_camera_near = @shadow_camera_near
      light.shadow_camera_far = @shadow_camera_far
      light.shadow_camera_fov = @shadow_camera_fov

      light.shadow_camera_visible = @shadow_camera_visible

      light.shadow_bias = @shadow_bias
      light.shadow_darkness = @shadow_darkness

      light.shadow_map_width = @shadow_map_width
      light.shadow_map_height = @shadow_map_height

      return light
    end
  end
end
