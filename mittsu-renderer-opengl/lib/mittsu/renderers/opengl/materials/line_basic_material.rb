module Mittsu
  class LineBasicMaterial
    def refresh_uniforms(uniforms)
      uniforms['diffuse'].value = color
      uniforms['opacity'].value = opacity
    end

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :basic
    end
  end
end
