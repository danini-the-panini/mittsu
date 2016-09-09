module Mittsu
  class PointLight
    TYPE = :point

    class Cache < Struct.new(:length, :count, :colors, :distances, :positions, :decays)
      def initialize
        super(0, 0, [], [], [], [])
      end

      def reset
        self.length = 0
      end
    end

    def setup_specific(index)
      offset = index * 3;

      OpenGLHelper.set_color_linear(@cache.colors, offset, color, intensity)

      @_vector3.set_from_matrix_position(matrix_world)

      positions = @cache.positions
      positions[offset]     = @_vector3.x
      positions[offset + 1] = @_vector3.y
      positions[offset + 2] = @_vector3.z

      # distance is 0 if decay is 0, because there is no attenuation at all.
      @cache.distances[index] = distance
      @cache.decays[index] = distance.zero? ? 0.0 : decay
    end

    def to_sym
      :point
    end
  end
end
