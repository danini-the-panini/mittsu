module Mittsu
  class OpenGLHemisphereLight < OpenGLLight
    TYPE = :hemi

    class Cache < Struct.new(:length, :count, :sky_colors, :ground_colors, :positions)
      def initialize
        super(0, 0, [], [], [])
      end

      def reset
        self.length = 0
      end
    end

    def setup_specific(index)
      offset = index * 3

      @_direction.set_from_matrix_position(@light.matrix_world)
      @_direction.normalize

      positions = @cache.positions
      positions[offset]     = @_direction.x
      positions[offset + 1] = @_direction.y
      positions[offset + 2] = @_direction.z

      sky_color = @light.color
      ground_color = @light.ground_color

      OpenGLHelper.set_color_linear(@cache.sky_colors, offset, sky_color, @light.intensity )
      OpenGLHelper.set_color_linear(@cache.ground_colors, offset, ground_color, @light.intensity)
    end

    def self.null_remaining_lights(cache)
      super(cache, cache.ground_colors)
      super(cache, cache.sky_colors)
    end
  end
end
