module Mittsu
  class OpenGLMeshPhongMaterial < OpenGLMeshBasicMaterial
    def needs_face_normals?
      false
    end

    def refresh_uniforms(uniforms)
      super

      uniforms['shininess'].value = @material.shininess

      uniforms['emissive'].value = @material.emissive
      uniforms['specular'].value = @material.specular

      if @material.wrap_around
        uniforms['wrapRGB'].value.copy(@material.wrap_rgb)
      end
    end
  end
end
