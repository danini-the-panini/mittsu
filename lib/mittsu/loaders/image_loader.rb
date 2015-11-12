require 'rmagick'
require 'mittsu/extras/image'

module Mittsu
  class ImageLoader
    attr_accessor :manager

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
    end

    def load(url, flip: false, flop: false)
      chache_url = "#{url}?flip=#{flip}&flop=#{flop}"
      cached = Cache.get(url)
      return cached unless cached.nil?

      rm_image = Magick::Image.read(url).first
      rm_image = rm_image.flip if flip
      rm_image = rm_image.flop if flop
      rgba_data = rm_image.to_blob { |i|
        i.format = "RGBA"
        i.depth = 8
      }

      image = Image.new(rm_image.columns, rm_image.rows, rgba_data)

      Cache.add(url, image)
      @manager.item_start(url)
      image
    end
  end
end
