module Mittsu
  class OpenGLCompressedTexture < OpenGLTexture
    def update_specific
      gl_format = GL_MITTSU_PARAMS[@texture.format]
      gl_type = GL_MITTSU_PARAMS[@texture.type]
      mipmaps = @texture.mipmaps

      mipmaps.each_with_index do |mipmap, i|
        if @texture.format != RGBAFormat && @texture.format != RGBFormat
          if @renderer.compressed_texture_formats.include?(gl_format)
            glCompressedTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, mipmap.data)
          else
            puts 'WARNING: Mittsu::OpenGLTexture: Attempt to load unsupported compressed texture format in #update_texture'
          end
        else
          glTexImage2D(GL_TEXTURE_2D, i, gl_format, mipmap.width, mipmap.height, 0, gl_format, gl_type, mipmap.data)
        end
      end
    end
  end
end
