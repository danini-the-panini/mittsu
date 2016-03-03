module Mittsu
  module OpenGLHelper
    def glCreateBuffer
      @_b ||= ' '*8
      glGenBuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateTexture
      @_b ||= ' '*8
      glGenTextures(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateVertexArray
      @_b ||= ' '*8
      glGenVertexArrays(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateFramebuffer
      @_b ||= ' '*8
      glGenFramebuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateRenderbuffer
      @_b ||= ' '*8
      glGenRenderbuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def array_to_ptr_easy(data)
      if data.first.is_a?(Float)
        size_of_element = Fiddle::SIZEOF_FLOAT
        format_of_element = 'F'
        # data.map!{ |d| d.nil? ? 0.0 : d }
      else
        size_of_element = Fiddle::SIZEOF_INT
        format_of_element = 'L'
        # data.map!{ |d| d.nil? ? 0 : d }
      end
      size = data.length * size_of_element
      array_to_ptr(data, size, format_of_element)
    end

    def array_to_ptr(data, size, format)
      ptr = Fiddle::Pointer.malloc(size)
      ptr[0,size] = data.pack(format * data.length)
      ptr
    end

    def glBufferData_easy(target, data, usage)
      ptr = array_to_ptr_easy(data)
      glBufferData(target, ptr.size, ptr, usage)
    end

    def glGetParameter(pname)
      @_b ||= ' '*8
      glGetIntegerv(pname, @_b)
      @_b.unpack('L')[0]
    end

    class << self
      def mark_uniforms_lights_needs_update(uniforms, value)
        uniforms['ambientLightColor'].needs_update = value

        uniforms['directionalLightColor'].needs_update = value
        uniforms['directionalLightDirection'].needs_update = value

        uniforms['pointLightColor'].needs_update = value
        uniforms['pointLightPosition'].needs_update = value
        uniforms['pointLightDistance'].needs_update = value
        uniforms['pointLightDecay'].needs_update = value

        uniforms['spotLightColor'].needs_update = value
        uniforms['spotLightPosition'].needs_update = value
        uniforms['spotLightDistance'].needs_update = value
        uniforms['spotLightDirection'].needs_update = value
        uniforms['spotLightAngleCos'].needs_update = value
        uniforms['spotLightExponent'].needs_update = value
        uniforms['spotLightDecay'].needs_update = value

        uniforms['hemisphereLightSkyColor'].needs_update = value
        uniforms['hemisphereLightGroundColor'].needs_update = value
        uniforms['hemisphereLightDirection'].needs_update = value
      end

      def refresh_uniforms_common(uniforms, material)
        uniforms['opacity'].value = material.opacity

        uniforms['diffuse'].value = material.color

        uniforms['map'].value = material.map
        uniforms['lightMap'].value = material.light_map
        uniforms['specularMap'].value = material.specular_map
        uniforms['alphaMap'].value = material.alpha_map

        if material.bump_map
          uniforms['bumpMap'].value = material.bump_map
          uniforms['bumpScale'].value = material.bump_scale
        end

        if material.normal_map
          uniforms['normalMap'].value = material.normal_map
          uniforms['normalScale'].value.copy( material.normal_scale )
        end

        # uv repeat and offset setting priorities
        #  1. color map
        #  2. specular map
        #  3. normal map
        #  4. bump map
        #  5. alpha map

        uv_scale_map = nil

        if material.map
          uv_scale_map = material.map
        elsif material.specular_map
          uv_scale_map = material.specular_map
        elsif material.normal_map
          uv_scale_map = material.normal_map
        elsif material.bump_map
          uv_scale_map = material.bump_map
        elsif material.alpha_map
          uv_scale_map = material.alpha_map
        end

        if !uv_scale_map.nil?
          offset = uv_scale_map.offset
          repeat = uv_scale_map.repeat

          uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
        end

        uniforms['envMap'].value = material.env_map
        # TODO: when OpenGLRenderTargetCube exists
        # uniforms['flipEnvMap'].value = material.envMap.is_a?(OpenGLRenderTargetCube) ? 1 : - 1

        uniforms['reflectivity'].value = material.reflectivity
        uniforms['refractionRatio'].value = material.refraction_ratio
      end

      def refresh_uniforms_phong(uniforms, material)
        uniforms['shininess'].value = material.shininess

        uniforms['emissive'].value = material.emissive
        uniforms['specular'].value = material.specular

        if material.wrap_around
          uniforms['wrapRGB'].value.copy(material.wrap_rgb)
        end
      end

      def refresh_uniforms_shadow(uniforms, lights)
        if uniforms['shadowMatrix']
          lights.select(&:cast_shadow).select { |light|
            light.is_a?(SpotLight) || (light.is_a?(DirectionalLight) && !light.shadow_cascade)
          }.each_with_index { |light, i|
            uniforms['shadowMap'].value[i] = light.shadow_map
            uniforms['shadowMapSize'].value[i] = light.shadow_map_size

            uniforms['shadowMatrix'].value[i] = light.shadow_matrix

            uniforms['shadowDarkness'].value[i] = light.shadow_darkness
            uniforms['shadowBias'].value[i] = light.shadow_bias
          }
        end
      end

      def refresh_uniforms_line(uniforms, material)
        uniforms['diffuse'].value = material.color
        uniforms['opacity'].value = material.opacity
      end

      def refresh_uniforms_lights(uniforms, lights)

        uniforms['ambientLightColor'].value = lights[:ambient].value

        uniforms['directionalLightColor'].value = lights[:directional].colors
        uniforms['directionalLightDirection'].value = lights[:directional].positions

        uniforms['pointLightColor'].value = lights[:point].colors
        uniforms['pointLightPosition'].value = lights[:point].positions
        uniforms['pointLightDistance'].value = lights[:point].distances
        uniforms['pointLightDecay'].value = lights[:point].decays

        uniforms['spotLightColor'].value = lights[:spot].colors
        uniforms['spotLightPosition'].value = lights[:spot].positions
        uniforms['spotLightDistance'].value = lights[:spot].distances
        uniforms['spotLightDirection'].value = lights[:spot].directions
        uniforms['spotLightAngleCos'].value = lights[:spot].angles_cos
        uniforms['spotLightExponent'].value = lights[:spot].exponents
        uniforms['spotLightDecay'].value = lights[:spot].decays

        uniforms['hemisphereLightSkyColor'].value = lights[:hemi].sky_colors
        uniforms['hemisphereLightGroundColor'].value = lights[:hemi].ground_colors
        uniforms['hemisphereLightDirection'].value = lights[:hemi].positions
      end

      def refresh_uniforms_lambert(uniforms, material)
        uniforms['emissive'].value = material.emissive

        if material.wrap_around
          uniforms['wrapRGB'].value.copy(material.wrap_rgb)
        end
      end

      def set_color_linear(array, offset, color, intensity)
        array[offset]     = color.r * intensity
        array[offset + 1] = color.g * intensity
        array[offset + 2] = color.b * intensity
      end

      def painter_sort_stable(a, b)
        if a.object.render_order != b.object.render_order
          a.object.render_order - b.object.render_order
        elsif a.material.id != b.material.id
          a.material.id - b.material.id
        elsif a.z != b.z
          a.z - b.z
        else
          a.object.id - b.object.id
        end
      end

      def reverse_painter_sort_stable(a, b)
        if a.object.render_order != b.object.render_order
          a.object.render_order - b.object.render_order
        elsif a.z != b.z
          b.z - a.z
        else
          a.id - b.id
        end
      end
    end
  end
end
