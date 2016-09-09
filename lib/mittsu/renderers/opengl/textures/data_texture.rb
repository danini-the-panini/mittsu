module Mittsu
  class DataTexture
    def update_specific
      gl_format = GL_MITTSU_PARAMS[format]
      gl_type = GL_MITTSU_PARAMS[type]
      is_image_power_of_two = Math.power_of_two?(image.width) && Math.power_of_two?(image.height)

      # use manually created mipmaps if available
      # if there are no manual mipmaps
      # set 0 level mipmap and then use GL to generate other mipmap levels

      if !mipmaps.empty? && is_image_power_of_two
        mipmaps.each_with_index do |mipmap, i|
          glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
        end
      else
        glTexImage2D(GL_TEXTURE_2D, 0, gl_format, image.width, image.height, 0, gl_format, gl_type, image.data)
      end
    end
  end
end
