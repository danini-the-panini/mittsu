module Mittsu
  class OpenGLLineBasicMaterial < OpenGLMaterial
    def refresh_uniforms(uniforms)
      uniforms['diffuse'].value = @material.color
      uniforms['opacity'].value = @material.opacity
    end

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :basic
    end
  end
end
