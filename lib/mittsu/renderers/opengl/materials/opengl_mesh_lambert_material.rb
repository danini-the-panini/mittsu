module Mittsu
  class OpenGLMeshLambertMaterial < OpenGLMeshBasicMaterial
    def refresh_uniforms(uniforms)
      super

      uniforms['emissive'].value = @material.emissive

      if @material.wrap_around
        uniforms['wrapRGB'].value.copy(@material.wrap_rgb)
      end
    end

    def needs_view_matrix_uniform?
      true
    end

    def needs_lights?
      true
    end

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :lambert
    end
  end
end
