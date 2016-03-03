module Mittsu
  class OpenGLMeshBasicMaterial < OpenGLMaterial
    def refresh_uniforms(uniforms)
      uniforms['opacity'].value = @material.opacity
      uniforms['diffuse'].value = @material.color

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
        uniforms['normalScale'].value.copy( @material.normal_scale )
      end

      # uv repeat and offset setting priorities
      #  1. color map
      #  2. specular map
      #  3. normal map
      #  4. bump map
      #  5. alpha map

      uv_scale_map = nil

      if @material.map
        uv_scale_map = @material.map
      elsif @material.specular_map
        uv_scale_map = @material.specular_map
      elsif @material.normal_map
        uv_scale_map = @material.normal_map
      elsif @material.bump_map
        uv_scale_map = @material.bump_map
      elsif @material.alpha_map
        uv_scale_map = @material.alpha_map
      end

      if !uv_scale_map.nil?
        offset = uv_scale_map.offset
        repeat = uv_scale_map.repeat

        uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
      end

      uniforms['envMap'].value = @material.env_map
      # TODO: when OpenGLRenderTargetCube exists
      # uniforms['flipEnvMap'].value = @material.envMap.is_a?(OpenGLRenderTargetCube) ? 1 : - 1

      uniforms['reflectivity'].value = @material.reflectivity
      uniforms['refractionRatio'].value = @material.refraction_ratio
    end
  end
end
