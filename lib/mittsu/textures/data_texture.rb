require 'mittsu/textures/texture'

module Mittsu
  class DataTexture < Texture
    def initialize(data, width, height, format = RGBAFormat, type = UnsignedByteType, mapping = DEFAULT_MAPPING, wrap_s = ClampToEdgeWrapping, wrap_t = ClampToEdgeWrapping, mag_filter = LinearFilter, min_filter = LinearMipMapLinearFilter, anisotropy = 1)
      super(null, mapping, wrap_s, wrap_t, mag_filter, min_filter, format, type, anisotropy)

      @image = { data: data, width: width, height: height }
    end

    def clone
      texture = DataTexture.new
      super(texture)
      texture
    end
  end
end
