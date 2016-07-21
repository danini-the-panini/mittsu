module Mittsu
  class SpotLight
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

      OpenGLHelper.set_color_linear(@cache.colors, offset, color, intensity)

      @_direction.set_from_matrix_position(matrix_world)

      positions = @cache.positions
      positions[offset]     = @_direction.x
      positions[offset + 1] = @_direction.y
      positions[offset + 2] = @_direction.z

      @cache.distances[index] = distance

      @_vector3.set_from_matrix_position(target.matrix_world)
      @_direction.sub(@_vector3)
      @_direction.normalize

      directions = @cache.directions
      directions[offset]     = @_direction.x
      directions[offset + 1] = @_direction.y
      directions[offset + 2] = @_direction.z

      @cache.angles_cos[index] = Math.cos(angle)
      @cache.exponents[index] = exponent;
      @cache.decays[index] = distance.zero? ? 0.0 : decay
    end

    def to_sym
      :spot
    end
  end
end
