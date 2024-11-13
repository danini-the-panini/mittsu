require 'mittsu/textures/texture'

module Mittsu
  class CompressedTexture < Texture
    attr_accessor :mipmaps

    def initialize(mipmaps = nil, width = nil, height = nil, format = RGBAFormat, type = UnsignedByteType, mapping = DEFAULT_MAPPING, wrap_s = ClampToEdgeWrapping, wrap_t = ClampToEdgeWrapping, mag_filter = LinearFilter, min_filter = LinearMipMapLinearFilter, anisotropy = 1)
      super(null, mapping, wrap_s, wrap_t, mag_filter, min_filter, format, type, anisotropy)

      @image = { width: width, height: height }
      @mipmaps = mipmaps

      # no flipping for cube textures
      # (also flipping doesn't work for compressed textures )

      @flip_y = false

      # can't generate mipmaps for compressed textures
      # mips must be embedded in DDS files

      @generate_mipmaps = false
    end

    def clone
      texture = CompressedTexture.new
      super(texture)
      texture
    end
  end
end
