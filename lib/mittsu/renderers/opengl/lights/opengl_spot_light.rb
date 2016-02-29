module Mittsu
  class OpenGLSpotLight < OpenGLLight
    TYPE = :spot

    class Cache < Struct.new(:length, :count, :colors, :directions, :distances, :positions, :exponents, :angles_cos, :decays)
      def initialize
        super(0, 0, [], [], [], [], [], [], [])
      end

      def reset
        self.length = 0
      end
    end

    def setup_specific(index)
      offset = index * 3

      OpenGLHelper.set_color_linear(@cache.colors, offset, @light.color, @light.intensity)

      @_direction.set_from_matrix_position(@light.matrix_world)

      positions = @cache.positions
      positions[offset]     = @_direction.x
      positions[offset + 1] = @_direction.y
      positions[offset + 2] = @_direction.z

      @cache.distances[index] = @light.distance

      @_vector3.set_from_matrix_position(@light.target.matrix_world)
      @_direction.sub(@_vector3)
      @_direction.normalize

      directions = @cache.directions
      directions[offset]     = @_direction.x
      directions[offset + 1] = @_direction.y
      directions[offset + 2] = @_direction.z

      @cache.angles_cos[index] = Math.cos(@light.angle)
      @cache.exponents[index] = @light.exponent;
      @cache.decays[index] = @light.distance.zero? ? 0.0 : @light.decay
    end
  end
end
