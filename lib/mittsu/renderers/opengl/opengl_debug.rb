require 'opengl'

module OpenGLDebug
  module OpenGLProxy
    extend OpenGL
  end

  def self.load_lib
    OpenGL.load_lib
  end

  OpenGL.constants.each do |c|
    const_set c, OpenGL.const_get(c)
  end

  OpenGL.instance_methods.each do |m|
    define_method m do |*args|
      r = OpenGLProxy.send(m, *args)
      call = "#{m}(#{args})"
      ret = r.nil? ? '' : " => #{r}"
      puts "#{call}#{ret}"
      e = OpenGLProxy.glGetError
      raise "ERROR: #{e}" unless e == OpenGL::GL_NO_ERROR
      r
    end
  end
end
