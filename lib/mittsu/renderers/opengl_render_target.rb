module Mittsu
  class OpenGLRenderTarget < HashObject
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

    def initialize(width, height, options = {})
      super()

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

    def dispose
      dispatch_event(type: :dispose)
    end
  end
end
