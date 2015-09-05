require 'mittsu/lights/light'

module Mittsu
  class DirectionalLight < Light
    attr_accessor :target,
                  :intensity,
                  :cast_shadow,
                  :only_shadow,
                  :shadow_camera_near,
                  :shadow_camera_far,
                  :shadow_camera_left,
                  :shadow_camera_right,
                  :shadow_camera_top,
                  :shadow_camera_bottom,
                  :shadow_camera_visible,
                  :shadow_bias,
                  :shadow_darkness,
                  :shadow_map_width,
                  :shadow_map_height,
                  :shadow_cascade,
                  :shadow_cascade_offset,
                  :shadow_cascade_count,
                  :shadow_cascade_bias,
                  :shadow_cascade_width,
                  :shadow_cascade_height,
                  :shadow_cascade_near_z,
                  :shadow_cascade_far_z,
                  :shadow_cascade_array,
                  :shadow_map,
                  :shadow_map_size,
                  :shadow_camera,
                  :shadow_matrix

    def initialize(color = nil, intensity = 1.0)
      super(color)

      @type = 'DirectionalLight'

      @position.set(0.0, 1.0, 0.0)
      @target = Object3D.new

      @intensity = intensity

      @cast_shadow = false
      @only_shadow = false

      #

      @shadow_camera_near = 50.0
      @shadow_camera_far = 5000.0

      @shadow_camera_left = -500.0
      @shadow_camera_right = 500.0
      @shadow_camera_top = 500.0
      @shadow_camera_bottom = -500.0

      @shadow_camera_visible = false

      @shadow_bias = 0
      @shadow_darkness = 0.5

      @shadow_map_width = 512
      @shadow_map_height = 512

      #

      @shadow_cascade = false

      @shadow_cascade_offset = Vector3.new(0.0, 0.0, -1000.0)
      @shadow_cascade_count = 2

      @shadow_cascade_bias = [0, 0, 0]
      @shadow_cascade_width = [512, 512, 512]
      @shadow_cascade_height = [512, 512, 512]

      @shadow_cascade_near_z = [-1.000, 0.990, 0.998]
      @shadow_cascade_far_z  = [0.990, 0.998, 1.000]

      @shadow_cascade_array = []

      #

      @shadow_map = nil
      @shadow_map_size = nil
      @shadow_camera = nil
      @shadow_matrix = nil
    end

    def clone
      light = DirectionalLight.new
      super(light)

      light.target = @target.clone

      light.intensity = @intensity

      light.cast_shadow = @cast_shadow
      light.only_shadow = @only_shadow

      #

      light.shadow_camera_near = @shadow_camera_near
      light.shadow_camera_far = @shadow_camera_far

      light.shadow_camera_left = @shadow_camera_left
      light.shadow_camera_right = @shadow_camera_right
      light.shadow_camera_top = @shadow_camera_top
      light.shadow_camera_bottom = @shadow_camera_bottom

      light.shadow_camera_visible = @shadow_camera_visible

      light.shadow_bias = @shadow_bias
      light.shadow_darkness = @shadow_darkness

      light.shadow_map_width = @shadow_map_width
      light.shadow_map_height = @shadow_map_height

      #

      light.shadow_cascade = @shadow_cascade

      light.shadow_cascade_offset.copy(@shadow_cascade_offset)
      light.shadow_cascade_count = @shadow_cascade_count

    	light.shadow_cascade_bias = @shadow_cascade_bias.dup
    	light.shadow_cascade_width = @shadow_cascade_width.dup
    	light.shadow_cascade_height = @shadow_cascade_height.dup

    	light.shadow_cascade_near_z = @shadow_cascade_near_z.dup
    	light.shadow_cascade_far_z  = @shadow_cascade_far_z.dup
    end
  end
end
