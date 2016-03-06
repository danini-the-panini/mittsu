require 'opengl'

module OpenGLStub
  def self.load_lib
  end

  OpenGL.constants.each do |c|
    const_set c, OpenGL.const_get(c)
  end

  OpenGL.instance_methods.each do |m|
    define_method m do |*args|
    end
  end

  def self.get_platform
    :OPENGL_PLATFORM_TEST
  end
end

OpenGL = OpenGLStub
