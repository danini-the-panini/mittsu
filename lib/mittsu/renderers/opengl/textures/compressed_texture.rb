module Mittsu
  class CompressedTexture
    def update_specific
      gl_format = GL::MITTSU_PARAMS[format]
      gl_type = GL::MITTSU_PARAMS[type]

      mipmaps.each_with_index do |mipmap, i|
        if format != RGBAFormat && format != RGBFormat
          if @renderer.compressed_texture_formats.include?(gl_format)
            GL.CompressedTexImage2D(GL::TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
          else
            puts 'WARNING: Mittsu::Texture: Attempt to load unsupported compressed texture format in #update_texture'
          end
        else
          GL.TexImage2D(GL::TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
        end
      end
    end
  end
end
