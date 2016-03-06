module Mittsu
  class OpenGLPointLight < OpenGLLight
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

      OpenGLHelper.set_color_linear(@cache.colors, offset, @light.color, @light.intensity)

      @_vector3.set_from_matrix_position(@light.matrix_world)

      positions = @cache.positions
      positions[offset]     = @_vector3.x
      positions[offset + 1] = @_vector3.y
      positions[offset + 2] = @_vector3.z

      # distance is 0 if decay is 0, because there is no attenuation at all.
      @cache.distances[index] = @light.distance
      @cache.decays[index] = @light.distance.zero? ? 0.0 : @light.decay
    end

    def to_sym
      :point
    end
  end
end
