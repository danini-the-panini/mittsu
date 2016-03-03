module Mittsu
  class OpenGLMeshLambertMaterial < OpenGLMeshBasicMaterial
    def refresh_uniforms(uniforms)
      super

      uniforms['emissive'].value = @material.emissive

      if @material.wrap_around
        uniforms['wrapRGB'].value.copy(@material.wrap_rgb)
      end
    end
  end
end
