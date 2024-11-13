module Mittsu
  module OpenGLMaterialBasics
    def refresh_uniforms_basic(uniforms)
      refresh_map_uniforms(uniforms)
      refresh_env_map_uniforms(uniforms)
      refresh_other_uniforms(uniforms)
    end

    def refresh_map_uniforms(uniforms)
      uniforms['map'].value = map
      uniforms['lightMap'].value = light_map
      uniforms['specularMap'].value = specular_map
      uniforms['alphaMap'].value = alpha_map

      if bump_map
        uniforms['bumpMap'].value = bump_map
        uniforms['bumpScale'].value = bump_scale
      end

      if normal_map
        uniforms['normalMap'].value = normal_map
        uniforms['normalScale'].value.copy(normal_scale)
      end
    end

    def refresh_env_map_uniforms(uniforms)
      uv_scale_map = get_uv_scale_map

      if uv_scale_map
        offset = uv_scale_map.offset
        repeat = uv_scale_map.repeat

        uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
      end

      uniforms['envMap'].value = env_map
      # TODO: when OpenGLRenderTargetCube exists
      # uniforms['flipEnvMap'].value = envMap.is_a?(OpenGLRenderTargetCube) ? 1 : - 1
    end

    def refresh_other_uniforms(uniforms)
      uniforms['opacity'].value = opacity
      uniforms['diffuse'].value = color

      uniforms['reflectivity'].value = reflectivity
      uniforms['refractionRatio'].value = refraction_ratio
    end

    def get_uv_scale_map
      map ||
      specular_map ||
      normal_map ||
      bump_map ||
      alpha_map
    end
  end
end
