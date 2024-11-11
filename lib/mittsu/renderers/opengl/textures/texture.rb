module Mittsu
  class Texture
    attr_reader :opengl_texture

    def set(slot, renderer)
      @renderer = renderer

      GL.ActiveTexture(GL::TEXTURE0 + slot)

      if needs_update?
        update_opengl(@renderer)
      else
        GL.BindTexture(GL::TEXTURE_2D, @opengl_texture)
      end
    end

    def update_opengl(renderer)
      @renderer = renderer

      if !@initted
        @initted = true
        add_event_listener(:dispose, @renderer.method(:on_texture_dispose))
        @opengl_texture = GL.CreateTexture
        @renderer.info[:memory][:textures] += 1
      end

      GL.BindTexture(GL::TEXTURE_2D, @opengl_texture)

      # GL.PixelStorei(GL::UNPACK_FLIP_Y_WEBGL, flip_y) ???
      # GL.PixelStorei(GL::UNPACK_PREMULTIPLY_ALPHA_WEBGL, premultiply_alpha) ???
      GL.PixelStorei(GL::UNPACK_ALIGNMENT, unpack_alignment)

      self.image = @renderer.clamp_to_max_size(image)

      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)

      set_parameters(GL::TEXTURE_2D, is_image_power_of_two)

      update_specific

      if generate_mipmaps && is_image_power_of_two
        GL.GenerateMipmap(GL::TEXTURE_2D)
      end

      self.needs_update = false

      on_update.call if on_update
    end

    protected

    def set_parameters(texture_type, is_image_power_of_two)
      if is_image_power_of_two
        GL.TexParameteri(texture_type, GL::TEXTURE_WRAP_S, GL::MITTSU_PARAMS[wrap_s])
        GL.TexParameteri(texture_type, GL::TEXTURE_WRAP_T, GL::MITTSU_PARAMS[wrap_t])

        GL.TexParameteri(texture_type, GL::TEXTURE_MAG_FILTER, GL::MITTSU_PARAMS[mag_filter])
        GL.TexParameteri(texture_type, GL::TEXTURE_MIN_FILTER, GL::MITTSU_PARAMS[min_filter])
      else
        GL.TexParameteri(texture_type, GL::TEXTURE_WRAP_S, GL::CLAMP_TO_EDGE)
        GL.TexParameteri(texture_type, GL::TEXTURE_WRAP_T, GL::CLAMP_TO_EDGE)

        if wrap_s != ClampToEdgeWrapping || wrap_t != ClampToEdgeWrapping
          puts "WARNING: Mittsu::Texture: Texture is not power of two. Texture.wrap_s and Texture.wrap_t should be set to Mittsu::ClampToEdgeWrapping. (#{source_file})"
        end

        GL.TexParameteri(texture_type, GL::TEXTURE_MAG_FILTER, filter_fallback(mag_filter))
        GL.TexParameteri(texture_type, GL::TEXTURE_MIN_FILTER, filter_fallback(min_filter))

        if min_filter != NearestFilter && min_filter != LinearFilter
          puts "WARNING: Mittsu::Texture: Texture is not a power of two. Texture.min_filter should be set to Mittsu::NearestFilter or Mittsu::LinearFilter. (#{source_file})"
        end

        # TODO: anisotropic extension ???
      end
    end

  	# Fallback filters for non-power-of-2 textures
  	def filter_fallback(filter)
  		if filter == NearestFilter || filter == NearestMipMapNearestFilter || filter == NearestMipMapLinearFilter
  			GL::NEAREST
  		end

      GL::LINEAR
  	end

    def update_specific
      gl_format = GL::MITTSU_PARAMS[format]
      gl_type = GL::MITTSU_PARAMS[type]
      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)

      # use manually created mipmaps if available
      # if there are no manual mipmaps
      # set 0 level mipmap and then use GL to generate other mipmap levels

      if !mipmaps.empty? && is_image_power_of_two
        mipmaps.each_with_index do |mipmap, i|
          GL.TexImage2D(GL::TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
        end

        self.generate_mipmaps = false
      else
        GL.TexImage2D(GL::TEXTURE_2D, 0, gl_format, image.width, image.height, 0, gl_format, gl_type, image.data)
      end
    end
  end
end
