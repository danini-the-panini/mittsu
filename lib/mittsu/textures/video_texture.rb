require 'mittsu/textures/texture'

module Mittsu
  class VideoTexture < Texture
    def initialize(video, mapping = DEFAULT_MAPPING, wrap_s = ClampToEdgeWrapping, wrap_t = ClampToEdgeWrapping, mag_filter = LinearFilter, min_filter = LinearMipMapLinearFilter, format = RGBAFormat, type = UnsignedByteType, anisotropy = 1)
      super(video, mapping, wrap_s, wrap_t, mag_filter, min_filter, format, type, anisotropy)

      @generate_mipmaps = false

      # TODO: update ???
      # requestAnimationFrame( update );
      # if ( video.readyState === video.HAVE_ENOUGH_DATA ) {
      #   scope.needsUpdate = true;
      # }
    end
  end
end
