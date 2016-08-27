require 'opengl'
require 'mittsu/renderers/opengl/opengl_lib'

module OpenGLLib
  def self.discover
    Struct.new(:path, :file).new(nil, nil)
  end
end

module OpenGLStub
  def self.load_lib(*args)
  end

  OpenGL.constants.each do |c|
    const_set c, OpenGL.const_get(c)
  end

  OpenGL.instance_methods.each do |m|
    define_method m do |*args|
      nil
    end
  end

  def glGenVertexArrays(n, arrays)
    next_va = (@@_glGenVertexArrays ||= 1)
    @@_glGenVertexArrays += n
    arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
    nil
  end

  def glGenBuffers(n, arrays)
    next_va = (@@_glGenBuffers ||= 1)
    @@_glGenBuffers += n
    arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
    nil
  end

  def glGenTextures(n, arrays)
    next_va = (@@_glGenTextures ||= 1)
    @@_glGenTextures += n
    arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
    nil
  end

  def glGenFramebuffers(n, arrays)
    next_va = (@@_glGenFramebuffers ||= 1)
    @@_glGenFramebuffers += n
    arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
    nil
  end

  def glGenRenderbuffers(n, arrays)
    next_va = (@@_glGenRenderbuffers ||= 1)
    @@_glGenRenderbuffers += n
    arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
    nil
  end

  def glGetBooleanv(_, params)
    params[0] = [1].pack('C')
    nil
  end

  def glGetDoublev(_, params)
    params[0..-1] = [rand].pack('D')
    nil
  end

  def glGetFloatv(_, params)
    params[0..-1] = [rand].pack('F')
    nil
  end

  def glGetIntegerv(_, params)
    params[0..-1] = [4096].pack('L')
    nil
  end

  def glGetShaderiv(_, _, params)
    params[0..-1] = [4096].pack('L')
    nil
  end
  alias :glGetProgramiv :glGetShaderiv

  def glGetShaderInfoLog(_, _, length, infoLog)
    length[0...4] = [0].pack('L')
    nil
  end
  alias :glGetProgramInfoLog :glGetShaderInfoLog

  def glGetError()
    OpenGL::GL_NO_ERROR
  end

  def glFrontFace(mode)
    @@_glFrontFace = mode
  end

  def glCullFace(mode)
    @@_glCullFace = mode
  end

  def glEnable(cap)
    (@@_glEnable ||= {}).tap { |e| e[cap] = true }
  end

  def glDisable(cap)
    (@@_glEnable ||= {}).tap { |e| e[cap] = false }
  end

  def glIsEnabled(cap)
    (@@_glEnable ||= {})[cap]
  end

  def glGenLists(_range_)
    _range_
  end

  def glRenderMode(_mode_)
    0
  end

  def glIsList(_list_)
    true
  end

  def glIsTexture(_texture_)
    true
  end

  def glAreTexturesResident(_n_, _textures_, _residences_)
    true
  end

  def glIsQuery(_id_)
    true
  end

  def glIsBuffer(_buffer_)
    true
  end

  def glUnmapBuffer(_target_)
    true
  end

  def glCreateProgram()
    (@@_glCreateProgram ||= 1).tap { @@_glCreateProgram += 1 }
  end

  def glCreateShader(_type_)
    (@@_glCreateShader ||= 1).tap { @@_glCreateShader += 1 }
  end

  def glGetAttribLocation(_program_, _name_)
    (@@_glGetAttribLocation ||= 1).tap { @@_glGetAttribLocation += 1 }
  end

  def glGetUniformLocation(_program_, _name_)
    (@@_glGetUniformLocation ||= 1).tap { @@_glGetUniformLocation += 1 }
  end

  def glIsProgram(_program_)
    true
  end

  def glIsShader(_shader_)
    true
  end

  def glIsEnabledi(_target_, _index_)
    true
  end

  def glGetFragDataLocation(_program_, _name_)
    (@@_glGetFragDataLocation ||= 1).tap { @@_glGetFragDataLocation += 1 }
  end

  def glIsRenderbuffer(_renderbuffer_)
    true
  end

  def glIsFramebuffer(_framebuffer_)
    true
  end

  def glCheckFramebufferStatus(_target_)
    OpenGL::GL_FRAMEBUFFER_COMPLETE
  end

  def glIsVertexArray(_array_)
    true
  end

  def glGetUniformBlockIndex(_program_, _uniformBlockName_)
    (@@_glGetUniformBlockIndex ||= 1).tap { @@_glGetUniformBlockIndex += 1 }
  end

  def glIsSync(_sync_)
    true
  end

  def glClientWaitSync(_sync_, _flags_, _timeout_)
    OpenGL::GL_ALREADY_SIGNALED
  end

  def glGetFragDataIndex(_program_, _name_)
    (@@_glGetFragDataIndex ||= 1).tap { @@_glGetFragDataIndex += 1 }
  end

  def glIsSampler(_sampler_)
    true
  end

  def glGetSubroutineUniformLocation(_program_, _shadertype_, _name_)
    (@@_glGetSubroutineUniformLocation ||= 1).tap { @@_glGetSubroutineUniformLocation += 1 }
  end

  def glGetSubroutineIndex(_program_, _shadertype_, _name_)
    (@@_glGetSubroutineIndex ||= 1).tap { @@_glGetSubroutineIndex += 1 }
  end

  def glIsTransformFeedback(_id_)
    true
  end

  def glCreateShaderProgramv(_type_, _count_, _strings_)
    (@@_glCreateShaderProgramv ||= 1).tap { @@_glCreateShaderProgramv += 1 }
  end

  def glIsProgramPipeline(_pipeline_)
    true
  end

  def glGetProgramResourceIndex(_program_, _programInterface_, _name_)
    (@@_glGetProgramResourceIndex ||= 1).tap { @@_glGetProgramResourceIndex += 1 }
  end

  def glGetProgramResourceLocation(_program_, _programInterface_, _name_)
    (@@_glGetProgramResourceLocation ||= 1).tap { @@_glGetProgramResourceLocation += 1 }
  end

  def glGetProgramResourceLocationIndex(_program_, _programInterface_, _name_)
    (@@_glGetProgramResourceLocationIndex ||= 1).tap { @@_glGetProgramResourceLocationIndex += 1 }
  end

  def glGetDebugMessageLog(_count_, _bufSize_, _sources_, _types_, _ids_, _severities_, _lengths_, _messageLog_)
    0
  end

  def glUnmapNamedBuffer(_buffer_)
    true
  end

  def glCheckNamedFramebufferStatus(_framebuffer_, _target_)
    OpenGL::GL_FRAMEBUFFER_COMPLETE
  end

  def glGetGraphicsResetStatus()
    OpenGL::GL_NO_ERROR
  end

  def self.get_platform
    :OPENGL_PLATFORM_TEST
  end
end

OpenGL = OpenGLStub
