require 'mittsu/renderers/opengl/materials/opengl_material_basics'

module Mittsu
  class MeshBasicMaterial
    include OpenGLMaterialBasics

    def refresh_uniforms(uniforms)
      refresh_uniforms_basic(uniforms)
    end

    protected

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :basic
    end
  end
end
