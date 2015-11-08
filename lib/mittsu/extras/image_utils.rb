module Mittsu
  module ImageUtils
    def self.load_texture(url, mapping = Texture::DEFAULT_MAPPING)
      loader = ImageLoader.new

      Texture.new(nil, mapping).tap do |texture|
        image = loader.load(url)
        texture.image = image
        texture.needs_update = true

        texture.source_file = url
      end
    end

    def self.load_texture_cube(array, mapping = Texture::DEFAULT_MAPPING)
      images = HashArray.new

      loader = ImageLoader.new
      CubeTexture.new(images, mapping).tap do |texture|
        loaded = 0

        array.length.times do |i|
          texture.images[i] = loader.load(array[i])
          loaded += 1
          if loaded == 6
            texture.needs_update = true
          end
        end
      end
    end

    def self.get_normal_map(image, depth)
      # adapted from http://www.paulbrunt.co.uk/lab/heightnormal/

      # depth |= 1
      #
      # width = image.width
      # height = image.height

      # TODO: original version uses browser features ...
    end

    def self.generate_data_texture(width, height, color)
      size = width * height
      data = Array.new(3 * size) # Uint8Array

      r = (color.r * 255).floor
      g = (color.g * 255).floor
      b = (color.b * 255).floor

      size.times do |i|
        data[i * 3]     = r
        data[i * 3 + 1] = g
        data[i * 3 + 2] = b
      end

      texture = DataTexture.new(data, width, height, RGBFormat)
      texture.needs_update = true

      texture
    end

    private_class_method def self.cross(a, b)
      [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0]
      ]
    end

    private_class_method def self.subtract(a, b)
      [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
    end

    private_class_method def self.normalize(a)
      l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
      [a[0] / l, a[1] / l, a[2] / l]
    end
  end
end
