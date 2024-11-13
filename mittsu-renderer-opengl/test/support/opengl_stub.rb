require 'opengl'
require 'mittsu/renderers/opengl/opengl_lib'

module Mittsu
  module OpenGLLib
    def self.discover
      Struct.new(:path, :file).new(nil, nil)
    end
  end
end

module OpenGLStub
  def self.load_lib(*args)
    # stub
  end

  GL.constants.each do |c|
    const_set c, GL.const_get(c)
  end

  class << self
    GL::GL_FUNCTION_SYMBOLS.each do |m|
      define_method(m.to_s.gsub(/^gl/, '').to_sym) do |*args|
        nil
      end
    end

    def GenVertexArrays(n, arrays)
      next_va = (@@_GenVertexArrays ||= 1)
      @@_GenVertexArrays += n
      arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
      nil
    end

    def GenBuffers(n, arrays)
      next_va = (@@_GenBuffers ||= 1)
      @@_GenBuffers += n
      arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
      nil
    end

    def GenTextures(n, arrays)
      next_va = (@@_GenTextures ||= 1)
      @@_GenTextures += n
      arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
      nil
    end

    def GenFramebuffers(n, arrays)
      next_va = (@@_GenFramebuffers ||= 1)
      @@_GenFramebuffers += n
      arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
      nil
    end

    def GenRenderbuffers(n, arrays)
      next_va = (@@_GenRenderbuffers ||= 1)
      @@_GenRenderbuffers += n
      arrays[0...n*4] = n.times.map { |i| i + next_va }.pack('L'*n)
      nil
    end

    def GetBooleanv(_, params)
      params[0] = [1].pack('C')
      nil
    end

    def GetDoublev(_, params)
      params[0..-1] = [rand].pack('D')
      nil
    end

    def GetFloatv(_, params)
      params[0..-1] = [rand].pack('F')
      nil
    end

    def GetIntegerv(_, params)
      params[0..-1] = [4096].pack('L')
      nil
    end

    def GetShaderiv(_, _, params)
      params[0..-1] = [4096].pack('L')
      nil
    end
    alias :GetProgramiv :GetShaderiv

    def GetShaderInfoLog(_, _, length, infoLog)
      length[0...4] = [0].pack('L')
      nil
    end
    alias :GetProgramInfoLog :GetShaderInfoLog

    def GetError()
      GL::NO_ERROR
    end

    def FrontFace(mode)
      @@_FrontFace = mode
    end

    def CullFace(mode)
      @@_CullFace = mode
    end

    def Enable(cap)
      (@@_Enable ||= {}).tap { |e| e[cap] = true }
    end

    def Disable(cap)
      (@@_Enable ||= {}).tap { |e| e[cap] = false }
    end

    def IsEnabled(cap)
      (@@_Enable ||= {})[cap]
    end

    def GenLists(_range_)
      _range_
    end

    def RenderMode(_mode_)
      0
    end

    def IsList(_list_)
      true
    end

    def IsTexture(_texture_)
      true
    end

    def AreTexturesResident(_n_, _textures_, _residences_)
      true
    end

    def IsQuery(_id_)
      true
    end

    def IsBuffer(_buffer_)
      true
    end

    def UnmapBuffer(_target_)
      true
    end

    def CreateProgram()
      (@@_CreateProgram ||= 1).tap { @@_CreateProgram += 1 }
    end

    def CreateShader(_type_)
      (@@_CreateShader ||= 1).tap { @@_CreateShader += 1 }
    end

    def GetAttribLocation(_program_, _name_)
      (@@_GetAttribLocation ||= 1).tap { @@_GetAttribLocation += 1 }
    end

    def GetUniformLocation(_program_, _name_)
      (@@_GetUniformLocation ||= 1).tap { @@_GetUniformLocation += 1 }
    end

    def IsProgram(_program_)
      true
    end

    def IsShader(_shader_)
      true
    end

    def IsEnabledi(_target_, _index_)
      true
    end

    def GetFragDataLocation(_program_, _name_)
      (@@_GetFragDataLocation ||= 1).tap { @@_GetFragDataLocation += 1 }
    end

    def IsRenderbuffer(_renderbuffer_)
      true
    end

    def IsFramebuffer(_framebuffer_)
      true
    end

    def CheckFramebufferStatus(_target_)
      GL::FRAMEBUFFER_COMPLETE
    end

    def IsVertexArray(_array_)
      true
    end

    def GetUniformBlockIndex(_program_, _uniformBlockName_)
      (@@_GetUniformBlockIndex ||= 1).tap { @@_GetUniformBlockIndex += 1 }
    end

    def IsSync(_sync_)
      true
    end

    def ClientWaitSync(_sync_, _flags_, _timeout_)
      GL::ALREADY_SIGNALED
    end

    def GetFragDataIndex(_program_, _name_)
      (@@_GetFragDataIndex ||= 1).tap { @@_GetFragDataIndex += 1 }
    end

    def IsSampler(_sampler_)
      true
    end

    def GetSubroutineUniformLocation(_program_, _shadertype_, _name_)
      (@@_GetSubroutineUniformLocation ||= 1).tap { @@_GetSubroutineUniformLocation += 1 }
    end

    def GetSubroutineIndex(_program_, _shadertype_, _name_)
      (@@_GetSubroutineIndex ||= 1).tap { @@_GetSubroutineIndex += 1 }
    end

    def IsTransformFeedback(_id_)
      true
    end

    def CreateShaderProgramv(_type_, _count_, _strings_)
      (@@_CreateShaderProgramv ||= 1).tap { @@_CreateShaderProgramv += 1 }
    end

    def IsProgramPipeline(_pipeline_)
      true
    end

    def GetProgramResourceIndex(_program_, _programInterface_, _name_)
      (@@_GetProgramResourceIndex ||= 1).tap { @@_GetProgramResourceIndex += 1 }
    end

    def GetProgramResourceLocation(_program_, _programInterface_, _name_)
      (@@_GetProgramResourceLocation ||= 1).tap { @@_GetProgramResourceLocation += 1 }
    end

    def GetProgramResourceLocationIndex(_program_, _programInterface_, _name_)
      (@@_GetProgramResourceLocationIndex ||= 1).tap { @@_GetProgramResourceLocationIndex += 1 }
    end

    def GetDebugMessageLog(_count_, _bufSize_, _sources_, _types_, _ids_, _severities_, _lengths_, _messageLog_)
      0
    end

    def UnmapNamedBuffer(_buffer_)
      true
    end

    def CheckNamedFramebufferStatus(_framebuffer_, _target_)
      GL::FRAMEBUFFER_COMPLETE
    end

    def GetGraphicsResetStatus()
      GL::NO_ERROR
    end

    def get_platform
      :OPENGL_PLATFORM_TEST
    end
  end
end

GL = OpenGLStub
