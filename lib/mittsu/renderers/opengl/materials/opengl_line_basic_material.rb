module Mittsu
  class OpenGLLineBasicMaterial < OpenGLMaterial
    def refresh_uniforms(uniforms)
      uniforms['diffuse'].value = @material.color
      uniforms['opacity'].value = @material.opacity
    end
  end
end
