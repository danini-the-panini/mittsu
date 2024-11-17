module Mittsu
  class Uniform
    attr_accessor :type, :value, :needs_update, :array

    def initialize(type, value)
      super()
      @type, @value = type, value
      @needs_update = nil
    end

    def clone
      new_value = case self.value
      when Color, Vector2, Vector3, Vector4, Matrix4#, Texture # TODO: when Texture exists
        self.value.clone
      when Array
        self.value.dup
      else
        self.value
      end
      Uniform.new(self.type, new_value)
    end
  end
end
