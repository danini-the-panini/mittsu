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

    def needs_camera_position_uniform?
      true
    end

    def needs_view_matrix_uniform?
      true
    end

    def needs_lights?
      true
    end
  end
end
