require 'opengl'

ERROR_STRINGS = {
  OpenGL::GL_NO_ERROR => 'NO_ERROR',
  OpenGL::GL_INVALID_ENUM => 'INVALID_ENUM',
  OpenGL::GL_INVALID_VALUE => 'INVALID_VALUE',
  OpenGL::GL_INVALID_OPERATION => 'INVALID_OPERATION',
  OpenGL::GL_STACK_OVERFLOW => 'STACK_OVERFLOW',
  OpenGL::GL_STACK_UNDERFLOW => 'STACK_UNDERFLOW',
  OpenGL::GL_OUT_OF_MEMORY => 'OUT_OF_MEMORY',
  # OpenGL::GL_TABLE_TOO_LARGE => 'TABLE_TOO_LARGE'
}

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
      call = "#{m}(#{args.map { |s| s.to_s[0..20] }.join(', ')})"
      ret = r.nil? ? '' : " => #{r}"
      puts "#{call}#{ret}"
      e = OpenGLProxy.glGetError
      raise "ERROR: #{m} => #{ERROR_STRINGS[e]}" unless e == OpenGL::GL_NO_ERROR
      r
    end
  end
end
