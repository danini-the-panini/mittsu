module Mittsu
  class OpenGLShaderMaterial < OpenGLMaterial
    def needs_camera_position_uniform?
      true
    end

    def needs_view_matrix_uniform?
      true
    end
  end
end
