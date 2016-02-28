module Mittsu
  class OpenGLTexture
    attr_reader :opengl_texture

    def initialize(texture, renderer)
      @texture = texture
      @renderer = renderer
      @initted = false
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

      @texture.image = @renderer.clamp_to_max_size(@texture.image)

      image = @texture.image
      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)
      gl_format = @renderer.param_mittsu_to_gl(@texture.format)
      gl_type = @renderer.param_mittsu_to_gl(@texture.type)

      set_parameters(GL_TEXTURE_2D, is_image_power_of_two)

      mipmaps = @texture.mipmaps

      if @texture.is_a?(DataTexture)
        # use manually created mipmaps if available
        # if there are no manual mipmaps
        # set 0 level mipmap and then use GL to generate other mipmap levels

        if !mipmaps.empty? && is_image_power_of_two
          mipmaps.each_with_index do |mipmap, i|
            glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
          end
        else
          glTexImage2D(GL_TEXTURE_2D, 0, gl_format, image.width, image.height, 0, gl_format, gl_type, image.data)
        end
      elsif @texture.is_a?(CompressedTexture)
        mipmaps.each_with_index do |mipmap, i|
          if @texture.format != RGBAFormat && @texture.format != RGBFormat
            if @renderer.compressed_texture_formats.include?(gl_format)
              glCompressedTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
            else
              puts 'WARNING: Mittsu::OpenGLTexture: Attempt to load unsupported compressed texture format in #update_texture'
            end
          else
            glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
          end
        end
      else # regular texture (image, video, canvas)
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

      if @texture.generate_mipmaps && is_image_power_of_two
        glGenerateMipmap(GL_TEXTURE_2D)
      end

      @texture.needs_update = false

      @texture.on_update.call if @texture.on_update
    end

    protected

    def set_parameters(texture_type, is_image_power_of_two)
      if is_image_power_of_two
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_S, @renderer.param_mittsu_to_gl(@texture.wrap_s))
        glTexParameteri(texture_type, GL_TEXTURE_WRAP_T, @renderer.param_mittsu_to_gl(@texture.wrap_t))

        glTexParameteri(texture_type, GL_TEXTURE_MAG_FILTER, @renderer.param_mittsu_to_gl(@texture.mag_filter))
        glTexParameteri(texture_type, GL_TEXTURE_MIN_FILTER, @renderer.param_mittsu_to_gl(@texture.min_filter))
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
  end
end
