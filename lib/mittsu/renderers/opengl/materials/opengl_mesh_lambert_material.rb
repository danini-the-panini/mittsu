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
  end
end
