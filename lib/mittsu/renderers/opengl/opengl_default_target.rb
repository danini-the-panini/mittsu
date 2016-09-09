module Mittsu
  class OpenGLDefaultTarget
    attr_accessor :viewport_width, :viewport_height, :viewport_x, :viewport_y
    alias :width :viewport_width
    alias :height :viewport_height

    def initialize renderer
      @renderer = renderer
      @viewport_width = 0
      @viewport_height = 0
      @viewport_x = 0
      @viewport_y = 0
    end

    def framebuffer
      0
    end

    def update_mipmap
      # NOOP
    end

    def setup_buffers
      # NOOP
    end

    def use
      glBindFramebuffer(GL_FRAMEBUFFER, 0)
      use_viewport
    end

    def use_viewport
      glViewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
    end

    def set_and_use_viewport(x, y, width, height)
      set_viewport(x, y, width, height)
      use_viewport
    end

    def set_viewport(x, y, width, height)
      @viewport_x, @viewport_y = x, y
      set_viewport_size(width, height)
    end

    def set_viewport_size(width, height)
      @viewport_width, @viewport_height = width, height
    end
  end
end
