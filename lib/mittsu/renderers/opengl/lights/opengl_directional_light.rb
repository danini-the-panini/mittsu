module Mittsu
  class OpenGLDirectionalLight < OpenGLLight
    TYPE = :directional

    class Cache < Struct.new(:length, :count, :colors, :positions)
      def initialize
        super(0, 0, [], [])
      end

      def reset
        self.length = 0
      end
    end

    def setup_specific(index)
      offset = index * 3

      @_direction.set_from_matrix_position(@light.matrix_world)
      @_vector3.set_from_matrix_position(@light.target.matrix_world)
      @_direction.sub(@_vector3)
      @_direction.normalize

      positions = @cache.positions
      positions[offset]     = @_direction.x
      positions[offset + 1] = @_direction.y
      positions[offset + 2] = @_direction.z

      OpenGLHelper.set_color_linear(@cache.colors, offset, @light.color, @light.intensity)
    end

    def to_sym
      :directional
    end
  end
end
