require 'fiddle'

module Mittsu
  class OpenGLShader
    attr_reader :shader

    def initialize(type, string)
      @shader = GL.CreateShader(type)
      # filename = type == GL::VERTEX_SHADER ? 'vertex.glsl' : 'fragment.glsl'
      # File.write filename, string

      string_pointer = Fiddle::Pointer[string]
      string_length = Fiddle::Pointer[string.length]

      GL.ShaderSource(@shader, 1, string_pointer.ref, string_length.ref)
      GL.CompileShader(@shader)

      if !compile_status
        puts "ERROR: Mittsu::OpenGLShader: Shader couldn't compile"
      end

      log_info = shader_info_log
      if !log_info.empty?
        puts "WARNING: Mittsu::OpenGLShader: GL.GetShaderInfoLog, #{log_info}"
        puts add_line_numbers(string)
      end
    end

    private

    def compile_status
      ptr = ' '*8
      GL.GetShaderiv @shader, GL::COMPILE_STATUS, ptr
      ptr.unpack('L')[0]
    end

    def shader_info_log
      ptr = ' '*8
      GL.GetShaderiv @shader, GL::INFO_LOG_LENGTH, ptr
      length = ptr.unpack('L')[0]

      if length > 0
        log = ' '*length
        GL.GetShaderInfoLog @shader, length, ptr, log
        log.unpack("A#{length}")[0]
      else
        ''
      end
    end

    def add_line_numbers(string)
      string.split("\n").each_with_index.map { |line, i|
        line_number = "#{i + 1}".rjust(4, ' ')
        "#{line_number}: #{line}"
      }.join("\n")
    end
  end
end
