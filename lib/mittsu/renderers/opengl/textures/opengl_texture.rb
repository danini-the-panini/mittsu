module Mittsu
  class OpenGLTexture
    attr_reader :opengl_texture

    def initialize(texture, renderer)
      @texture = texture
      @renderer = renderer
      @initted = false
    end

    def set(slot)
      glActiveTexture(GL_TEXTURE0 + slot)

      if @texture.needs_update?
        update
      else
        glBindTexture(GL_TEXTURE_2D, @opengl_texture)
      end
    end

    def update
      if !@initted
        @initted = true
        @texture.add_event_listener(:dispose, @renderer.method(:on_texture_dispose))
        @opengl_texture = glCreateTexture
        @renderer.info[:memory][:textures] += 1
      end

      glBindTexture(GL_TEXTURE_2D, @opengl_texture)

      # glPixelStorei(GL_UNPACK_FLIP_Y_WEBGL, texture.flip_y) ???
      # glPixelStorei(GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiply_alpha) ???
      glPixelStorei(GL_UNPACK_ALIGNMENT, @texture.unpack_alignment)

      image = @texture.image = @renderer.clamp_to_max_size(@texture.image)

      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)

      set_parameters(GL_TEXTURE_2D, is_image_power_of_two)

      update_specific

      if @texture.generate_mipmaps && is_image_power_of_two
        glGenerateMipmap(GL_TEXTURE_2D)
      end

      @texture.needs_update = false

      @texture.on_update.call if @texture.on_update
    end

    protected

    def set_parameters(texture_type, is_image_power_of_two)
      if is_image_power_of_two
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_S, GL_MITTSU_PARAMS[@texture.wrap_s])
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_T, GL_MITTSU_PARAMS[@texture.wrap_t])

        glTexParameteri(texture_type, GL_TEXTURE_MAG_FILTER, GL_MITTSU_PARAMS[@texture.mag_filter])
        glTexParameteri(texture_type, GL_TEXTURE_MIN_FILTER, GL_MITTSU_PARAMS[@texture.min_filter])
      else
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

        if @texture.wrap_s != ClampToEdgeWrapping || @texture.wrap_t != ClampToEdgeWrapping
          puts "WARNING: Mittsu::OpenGLTexture: Texture is not power of two. Texture.wrap_s and Texture.wrap_t should be set to Mittsu::ClampToEdgeWrapping. (#{texture.source_file})"
        end

        glTexParameteri(texture_type, GL_TEXTURE_MAG_FILTER, filter_fallback(@texture.mag_filter))
        glTexParameteri(texture_type, GL_TEXTURE_MIN_FILTER, filter_fallback(@texture.min_filter))

        if @texture.min_filter != NearestFilter && @texture.min_filter != LinearFilter
          puts "WARNING: Mittsu::OpenGLTexture: Texture is not a power of two. Texture.min_filter should be set to Mittsu::NearestFilter or Mittsu::LinearFilter. (#{texture.source_file})"
        end

        # TODO: anisotropic extension ???
      end
    end

  	# Fallback filters for non-power-of-2 textures
  	def filter_fallback(filter)
  		if filter == NearestFilter || filter == NearestMipMapNearestFilter || f == NearestMipMapLinearFilter
  			GL_NEAREST
  		end

      GL_LINEAR
  	end

    def update_specific
      gl_format = GL_MITTSU_PARAMS[@texture.format]
      gl_type = GL_MITTSU_PARAMS[@texture.type]
      mipmaps = @texture.mipmaps
      image = @texture.image
      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)

      # use manually created mipmaps if available
      # if there are no manual mipmaps
      # set 0 level mipmap and then use GL to generate other mipmap levels

      if !mipmaps.empty? && is_image_power_of_two
        mipmaps.each_with_index do |mipmap, i|
          glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
        end

        @texture.generate_mipmaps = false
      else
        glTexImage2D(GL_TEXTURE_2D, 0, gl_format, @texture.image.width, @texture.image.height, 0, gl_format, gl_type, @texture.image.data)
      end
    end
  end
end
