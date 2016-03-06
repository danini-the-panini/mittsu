module Mittsu
  class OpenGLMeshBasicMaterial < OpenGLMaterial
    def refresh_uniforms(uniforms)
      refresh_map_uniforms(uniforms)
      refresh_env_map_uniforms(uniforms)
      refresh_other_uniforms(uniforms)
    end

    protected

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :basic
    end

    private

    def get_uv_scale_map
      @material.map ||
      @material.specular_map ||
      @material.normal_map ||
      @material.bump_map ||
      @material.alpha_map
    end

    def refresh_map_uniforms(uniforms)
      uniforms['map'].value = @material.map
      uniforms['lightMap'].value = @material.light_map
      uniforms['specularMap'].value = @material.specular_map
      uniforms['alphaMap'].value = @material.alpha_map

      if @material.bump_map
        uniforms['bumpMap'].value = @material.bump_map
        uniforms['bumpScale'].value = @material.bump_scale
      end

      if @material.normal_map
        uniforms['normalMap'].value = @material.normal_map
        uniforms['normalScale'].value.copy(@material.normal_scale)
      end
    end

    def refresh_env_map_uniforms(uniforms)
      uv_scale_map = get_uv_scale_map

      if uv_scale_map
        offset = uv_scale_map.offset
        repeat = uv_scale_map.repeat

        uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
      end

      uniforms['envMap'].value = @material.env_map
      # TODO: when OpenGLRenderTargetCube exists
      # uniforms['flipEnvMap'].value = @material.envMap.is_a?(OpenGLRenderTargetCube) ? 1 : - 1
    end

    def refresh_other_uniforms(uniforms)
      uniforms['opacity'].value = @material.opacity
      uniforms['diffuse'].value = @material.color

      uniforms['reflectivity'].value = @material.reflectivity
      uniforms['refractionRatio'].value = @material.refraction_ratio
    end
  end
end
