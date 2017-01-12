begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end

require 'mittsu/extras/image'

module Mittsu
  class ImageLoader
    attr_accessor :manager

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
    end

    def load(url, flip: false, flop: false)
      chache_url = "#{url}?flip=#{flip}&flop=#{flop}"
      cached = Cache.get(chache_url)
      return cached unless cached.nil?

      png_image = ChunkyPNG::Image.from_file(url)
      png_image.flip_horizontally! if flip
      png_image.flip_vertically! if flop
      rgba_data = png_image.to_rgba_stream

      image = Image.new(png_image.width, png_image.height, rgba_data)

      Cache.add(url, image)
      @manager.item_start(url)
      image
    end
  end
end
