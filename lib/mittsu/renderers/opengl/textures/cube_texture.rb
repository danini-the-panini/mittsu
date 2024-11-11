module Mittsu
  class CubeTexture
    def set(slot, renderer)
      @renderer = renderer

      if image.length == 6
        if needs_update?
          if !image[:_opengl_texture_cube]
            add_event_listener(:dispose, @renderer.method(:on_texture_dispose))
            image[:_opengl_texture_cube] = GL.CreateTexture
            @renderer.info[:memory][:textures] += 1
          end

          GL.ActiveTexture(GL::TEXTURE0 + slot)
          GL.BindTexture(GL::TEXTURE_CUBE_MAP, image[:_opengl_texture_cube])

          # GL.PixelStorei(GL::UNPACK_FLIP_Y_WEBGL, texture.flip_y)

          is_compressed = is_a?(CompressedTexture)
          is_data_texture = image[0].is_a?(DataTexture)

          cube_image = [];

          6.times do |i|
            if @auto_scale_cubemaps && !is_compressed && !is_data_texture
              cube_image[i] = clamp_to_max_size(image[i], @_max_cubemap_size)
            else
              cube_image[i] = is_data_texture ? image[i].image : image[i];
            end
          end

          img = cube_image[0]
          is_image_power_of_two = Math.power_of_two?(img.width) && Math.power_of_two?(img.height)
          gl_format = GL::MITTSU_PARAMS[format]
          gl_type = GL::MITTSU_PARAMS[type]

          set_parameters(GL::TEXTURE_CUBE_MAP, is_image_power_of_two)

          6.times do |i|
            if !is_compressed
              if is_data_texture
                GL.TexImage2D(GL::TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              else
                GL.TexImage2D(GL::TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              end
            else
              mipmaps = cube_image[i].mipmaps

              mipmaps.each_with_index do |mipmap, j|
                if format != RGBAFormat && format != RGBFormat
                  if @renderer.compressed_texture_formats.include?(gl_format)
                    GL.CompressedTexImage2D(GL::TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
                  else
                    puts "WARNING: Mittsu::OpenGLCubeTexture: Attempt to load unsupported compressed texture format in #set"
                  end
                else
                  GL.TexImage2D(GL::TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
                end
              end
            end
          end

          if generate_mipmaps && is_image_power_of_two
            GL.GenerateMipmap(GL::TEXTURE_CUBE_MAP)
          end

          self.needs_update = false

          on_update.call if on_update
        else
          GL.ActiveTexture(GL::TEXTURE0 + slot)
          GL.BindTexture(GL::TEXTURE_CUBE_MAP, image[:_opengl_texture_cube])
        end
      end
    end
  end
end
