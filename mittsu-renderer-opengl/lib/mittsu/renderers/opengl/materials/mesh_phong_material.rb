require 'mittsu/renderers/opengl/materials/opengl_material_basics'

module Mittsu
  class MeshPhongMaterial
    include OpenGLMaterialBasics

    def needs_face_normals?
      false
    end

    def refresh_uniforms(uniforms)
      refresh_uniforms_basic(uniforms)

      uniforms['shininess'].value = shininess

      uniforms['emissive'].value = emissive
      uniforms['specular'].value = specular

      if wrap_around
        uniforms['wrapRGB'].value.copy(wrap_rgb)
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

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :phong
    end
  end
end
