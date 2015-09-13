require 'fiddle'

module Mittsu
  class OpenGLShader
    attr_reader :shader

    def initialize(type, string)
      @shader = glCreateShader(type)
      # filename = type == GL_VERTEX_SHADER ? 'vertex.glsl' : 'fragment.glsl'
      # File.write filename, string

      string_pointer = Fiddle::Pointer[string]
      string_length = Fiddle::Pointer[string.length]

      glShaderSource(@shader, 1, string_pointer.ref, string_length.ref)
      glCompileShader(@shader)

      if !compile_status
        puts "ERROR: Mittsu::OpenGLShader: Shader couldn't compile"
      end

      log_info = shader_info_log
      if !log_info.empty?
        puts "WARNING: Mittsu::OpenGLShader: glGetShaderInfoLog, #{log_info}"
        puts add_line_numbers(string)
      end
    end

    private

    def compile_status
      ptr = ' '*8
      glGetShaderiv @shader, GL_COMPILE_STATUS, ptr
      ptr.unpack('L')[0]
    end

    def shader_info_log
      ptr = ' '*8
      glGetShaderiv @shader, GL_INFO_LOG_LENGTH, ptr
      length = ptr.unpack('L')[0]

      if length > 0
        log = ' '*length
        glGetShaderInfoLog @shader, length, ptr, log
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
