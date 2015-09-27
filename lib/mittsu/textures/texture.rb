require 'securerandom'
require 'mittsu/math'
require 'mittsu/core/event_dispatcher'
require 'mittsu/constants'
require 'mittsu/core/hash_object'

module Mittsu
  class Texture < HashObject
    include EventDispatcher

    DEFAULT_IMAGE = nil
    DEFAULT_MAPPING = UVMapping

    attr_reader :id, :uuid, :type

    attr_accessor :image, :name, :source_file, :mipmaps, :offset, :repeat, :generate_mipmaps, :premultiply_alpha, :filp_y, :unpack_alignment, :on_update, :mipmaps, :mapping, :wrap_s, :wrap_t, :mag_filter, :min_filter, :anisotropy, :format, :type

    def initialize(image = DEFAULT_IMAGE, mapping = DEFAULT_MAPPING, wrap_s = ClampToEdgeWrapping, wrap_t = ClampToEdgeWrapping, mag_filter = LinearFilter, min_filter = LinearMipMapLinearFilter, format = RGBAFormat, type = UnsignedByteType, anisotropy = 1)
      super()

      @id = (@@id ||= 1).tap { @@id += 1 }
      @uuid = SecureRandom.uuid

      @name = ''
      @source_file = ''

      @image = image
      @mipmaps = []

      @mapping = mapping
      @wrap_s, @wrap_t = wrap_s, wrap_t
      @mag_filter, @min_filter = mag_filter, min_filter
      @anisotropy = anisotropy
      @format, @type = format, type

      @offset = Vector2.new(0.0, 0.0)
      @repeat = Vector2.new(1.0, 1.0)

      @generate_mipmaps = true
      @premultiply_alpha = false
      @filp_y = true
      @unpack_alignment = 4 # valid values: 1, 2, 4, 8 (see http://www.khronos.org/opengles/sdk/docs/man/xhtml/glPixelStorei.xml)

      @_needs_update = false
      @on_update = nil
    end

    def needs_update?
      @_needs_update
    end

    def needs_update=(value)
      update if value
      @_needs_update = value
    end

    def clone(texture = Texture.new)
      texture.image = @image
      texture.mipmaps = @mipmaps.dup

      texture.mapping = @mapping

      texture.wrap_s = @wrap_s
      texture.wrap_t = @wrap_t

      texture.mag_filter = @mag_filter
      texture.min_filter = @min_filter

      texture.anisotropy = @anisotropy

      texture.format = @format
      texture.type = @type

      texture.offset.copy(@offset)
      texture.repeat.copy(@repeat)

      texture.generate_mipmaps = @generate_mipmaps
      texture.premultiply_alpha = @premultiply_alpha
      texture.flip_y = @flip_y

      texture
    end

    def update
      dispatch_event type: :update
    end

    def dispose
      dispatch_event type: :dispose
    end
  end
end
