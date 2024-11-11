module Mittsu
  class OpenGLRenderTarget < Texture
    include EventDispatcher

    attr_accessor :width,
                  :height,
                  :wrap_s,
                  :wrap_t,
                  :mag_filter,
                  :min_filter,
                  :anisotropy,
                  :offset,
                  :repeat,
                  :format,
                  :type,
                  :depth_buffer,
                  :stencil_buffer,
                  :generate_mipmaps,
                  :share_depth_from

    attr_reader :framebuffer

    attr_writer :renderer

    def initialize(width, height, options = {})
      super(self, nil)

      @width = width
      @height = height

      @wrap_s = options.fetch(:wrap_s, ClampToEdgeWrapping)
      @wrap_t = options.fetch(:wrap_t, ClampToEdgeWrapping)

      @mag_filter = options.fetch(:mag_filter, LinearFilter)
      @min_filter = options.fetch(:min_filter, LinearMipMapLinearFilter)

      @anisotropy = options.fetch(:anisotropy, 1.0);

      @offset = Vector2.new(0.0, 0.0)
      @repeat = Vector2.new(1.0, 1.0)

      @format = options.fetch(:format, RGBAFormat)
      @type = options.fetch(:type, UnsignedByteType)

      @depth_buffer = options.fetch(:depth_buffer, true)
      @stencil_buffer = options.fetch(:stencil_buffer, true)

      @generate_mipmaps = true

      @share_depth_from = options.fetch(:share_depth_from, nil)
    end

    def set_size(width, height)
      @width = width
      @height = height
    end

    def needs_update?
      false
    end

    def clone
      OpenGLRenderTarget.new(@width, @height).tap do |tmp|
        tmp.renderer = @renderer

    		tmp.wrap_s = @wrap_s
    		tmp.wrap_t = @wrap_t

    		tmp.mag_filter = @mag_filter
    		tmp.min_filter = @min_filter

    		tmp.anisotropy = @anisotropy

    		tmp.offset.copy(@offset)
    		tmp.repeat.copy(@repeat)

    		tmp.format = @format
    		tmp.type = @type

    		tmp.depth_buffer = @depth_buffer
    		tmp.stencil_buffer = @stencil_buffer

    		tmp.generate_mipmaps = @generate_mipmaps

    		tmp.share_depth_from = @share_depth_from
      end
    end

    def setup_buffers
      return unless @framebuffer.nil?

      # TODO: when OpenGLRenderTargetCube exists
      is_cube = false # render_target.is_a? OpenGLRenderTargetCube

      @depth_buffer = true if @depth_buffer.nil?
      @stencil_buffer = true if @stencil_buffer.nil?

      add_event_listener(:dispose, @renderer.method(:on_render_target_dispose))

      @opengl_texture = GL.CreateTexture

      @renderer.info[:memory][:textures] += 1

      # Setup texture, create render and frame buffers

      is_target_power_of_two = Math.power_of_two?(@width) && Math.power_of_two?(@height)
      gl_format = GL::MITTSU_PARAMS[@format]
      gl_type = GL::MITTSU_PARAMS[@type]

      if is_cube
        # TODO
      else
        @framebuffer = GL.CreateFramebuffer

        if @share_depth_from
          @renderbuffer = share_depth_from.renderbuffer
        else
          @renderbuffer = GL.CreateRenderbuffer
        end

        GL.BindTexture(GL::TEXTURE_2D, @opengl_texture)
        set_parameters(GL::TEXTURE_2D, is_target_power_of_two)

        GL.TexImage2D(GL::TEXTURE_2D, 0, gl_format, @width, @height, 0, gl_format, gl_type, nil)

        setup_framebuffer(GL::TEXTURE_2D)

        if @share_depth_from
          if @depth_buffer && !@stencil_buffer
            GL.FramebufferRenderbuffer(GL::FRAMEBUFFER, GL::DEPTH_ATTACHMENT, GL::RENDERBUFFER, @renderbuffer)
          elsif @depth_buffer && @stencil_buffer
            GL.FramebufferRenderbuffer(GL::FRAMEBUFFER, GL::DEPTH_STENCIL_ATTACHMENT, GL::RENDERBUFFER, @renderbuffer)
          end
        else
          setup_renderbuffer
        end

        GL.GenerateMipmap(GL::TEXTURE_2D) if is_target_power_of_two
      end

      # Release everything

      if is_cube
        # TODO
      else
        GL.BindTexture(GL::TEXTURE_2D, 0)
      end

      GL.BindRenderbuffer(GL::RENDERBUFFER, 0)
      GL.BindFramebuffer(GL::FRAMEBUFFER, 0)
    end

    def use
      GL.BindFramebuffer(GL::FRAMEBUFFER, @framebuffer)
      GL.Viewport(0, 0, @width, @height)
    end

    def dispose
      dispatch_event(type: :dispose)
    end

    def update_mipmap
      return if !@generate_mipmaps || @min_filter == NearestFilter || @min_filter == LinearFilter
      # TODO: when OpenGLRenderTargetCube exists
  		# 	GL.BindTexture(GL::TEXTURE_CUBE_MAP, @opengl_texture)
  		# 	GL.GenerateMipmap(GL::TEXTURE_CUBE_MAP)
  		# 	GL.BindTexture(GL::TEXTURE_CUBE_MAP, nil)
			GL.BindTexture(GL::TEXTURE_2D, @opengl_texture)
			GL.GenerateMipmap(GL::TEXTURE_2D)
			GL.BindTexture(GL::TEXTURE_2D, nil)
    end

    private

    def setup_framebuffer(texture_target)
      GL.BindFramebuffer(GL::FRAMEBUFFER, @framebuffer)
      GL.FramebufferTexture2D(GL::FRAMEBUFFER, GL::COLOR_ATTACHMENT0, texture_target, @opengl_texture, 0)
    end

    def setup_renderbuffer
      GL.BindRenderbuffer(GL::RENDERBUFFER, @renderbuffer)

      if @depth_buffer && !@stencil_buffer
        GL.RenderbufferStorage(GL::RENDERBUFFER, GL::DEPTH_COMPONENT16, @width, @height)
        GL.FramebufferRenderbuffer(GL::FRAMEBUFFER, GL::DEPTH_ATTACHMENT, GL::RENDERBUFFER, @renderbuffer)

        # TODO: investigate this (?):
    		# THREE.js - For some reason this is not working. Defaulting to RGBA4.
    		# } else if ( ! renderTarget.depthBuffer && renderTarget.stencilBuffer ) {
        #
    		# 	_gl.renderbufferStorage( _gl.RENDERBUFFER, _gl.STENCIL_INDEX8, renderTarget.width, renderTarget.height );
    		# 	_gl.framebufferRenderbuffer( _gl.FRAMEBUFFER, _gl.STENCIL_ATTACHMENT, _gl.RENDERBUFFER, renderbuffer );
      elsif @depth_buffer && @stencil_buffer
        GL.RenderbufferStorage(GL::RENDERBUFFER, GL::DEPTH_STENCIL, @width, @height)
        GL.FramebufferRenderbuffer(GL::FRAMEBUFFER, GL::DEPTH_STENCIL_ATTACHMENT, GL::RENDERBUFFER, @renderbuffer)
      else
        GL.RenderbufferStorage(GL::RENDERBUFFER, GL::RGBA4, @width, @height)
      end
    end
  end
end
