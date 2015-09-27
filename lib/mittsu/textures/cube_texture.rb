require 'mittsu/textures/texture'

module Mittsu
  class CubeTexture < Texture
    attr_accessor :images

    def initialize(images, mapping = DEFAULT_MAPPING, wrap_s = ClampToEdgeWrapping, wrap_t = ClampToEdgeWrapping, mag_filter = LinearFilter, min_filter = LinearMipMapLinearFilter, format = RGBAFormat, type = UnsignedByteType, anisotropy = 1)
      super(images, mapping, wrap_s, wrap_t, mag_filter, min_filter, format, type, anisotropy)

      @images = images
    end

    def clone(texture = CubeTexture.new)
      super(texture)
      texture.images = @images
      texture
    end
  end
end
