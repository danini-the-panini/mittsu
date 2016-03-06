module Mittsu
  class OpenGLCubeTexture < OpenGLTexture
    def set(slot)
      if @texture.image.length == 6
        if @texture.needs_update?
          if !@texture.image[:_opengl_texture_cube]
            @texture.add_event_listener(:dispose, @renderer.method(:on_texture_dispose))
            @texture.image[:_opengl_texture_cube] = glCreateTexture
            @renderer.info[:memory][:textures] += 1
          end

          glActiveTexture(GL_TEXTURE0 + slot)
          glBindTexture(GL_TEXTURE_CUBE_MAP, @texture.image[:_opengl_texture_cube])

          # glPixelStorei(GL_UNPACK_FLIP_Y_WEBGL, texture.flip_y)

          is_compressed = @texture.is_a?(CompressedTexture)
          is_data_texture = @texture.image[0].is_a?(DataTexture)

          cube_image = [];

          6.times do |i|
            if @auto_scale_cubemaps && !is_compressed && !is_data_texture
              cube_image[i] = clamp_to_max_size(@texture.image[i], @_max_cubemap_size)
            else
              cube_image[i] = is_data_texture ? @texture.image[i].image : @texture.image[i];
            end
          end

          image = cube_image[0]
          is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)
          gl_format = GL_MITTSU_PARAMS[@texture.format]
          gl_type = GL_MITTSU_PARAMS[@texture.type]

          set_parameters(GL_TEXTURE_CUBE_MAP, is_image_power_of_two)

          6.times do |i|
            if !is_compressed
              if is_data_texture
                glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              else
                glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, gl_format, cube_image[i].width, cube_image[i].height, 0, gl_format, gl_type, cube_image[i].data)
              end
            else
              mipmaps = cube_image[i].mipmaps

              mipmaps.each_with_index do |mipmap, j|
                if @texture.format != RGBAFormat && @texture.format != RGBFormat
                  if @renderer.compressed_texture_formats.include?(gl_format)
                    glCompressedTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
                  else
                    puts "WARNING: Mittsu::OpenGLCubeTexture: Attempt to load unsupported compressed texture format in #set"
                  end
                else
                  glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, j, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
                end
              end
            end
          end

          if @texture.generate_mipmaps && is_image_power_of_two
            glGenerateMipmap(GL_TEXTURE_CUBE_MAP)
          end

          @texture.needs_update = false

          @texture.on_update.call if @texture.on_update
        else
          glActiveTexture(GL_TEXTURE0 + slot)
          glBindTexture(GL_TEXTURE_CUBE_MAP, @texture.image[:_opengl_texture_cube])
        end
      end
    end
  end
end
