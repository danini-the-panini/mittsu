module Mittsu
  module RBSLLoader
    UNIFORM_RGX = /uniform\s+(\S+)\s+(\w+)(|\s+\=\s+(.+));/

    def self.load_shader(shader, chunks)
      shader.lines.flat_map(&:chomp).map{ |line|
        if line =~ /(\s*)#include\s+(\w+)/
          indentation = $1
          chunk_name = $2.to_sym

          chunks[chunk_name].lines.map(&:chomp).map{ |l|
            "#{indentation}#{l}"
          }
        else
          line
        end
      }.join("\n") + "\n"
    end

    def self.parse_int(str)
      str.to_i
    end

    def self.parse_ivec2(str)
      str =~ /ivec2\(([^\)]+)\)/
      $1.split(',').map(&:strip).map(&:to_i)
    end

    def self.parse_ivec3(str)
      str =~ /ivec3\(([^\)]+)\)/
      $1.split(',').map(&:strip).map(&:to_i)
    end

    def self.parse_ivec4(str)
      str =~ /ivec4\(([^\)]+)\)/
      $1.split(',').map(&:strip).map(&:to_i)
    end

    def self.parse_float(str)
      str.to_f
    end

    def self.parse_vec2(str)
      str =~ /vec2\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f)
      Vector2.new(*values)
    end

    def self.parse_vec3(str)
      str =~ /vec3\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f)
      Vector3.new(*values)
    end

    def self.parse_vec4(str)
      str =~ /vec4\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f)
      Vector4.new(*values)
    end

    def self.parse_color(str)
      str =~ /color\(([^\)]*)\)/
      values = $1.split(',').map(&:strip)
      if values.length == 1
        values = values.map(&:to_i)
      else
        values = values.map(&:to_f)
      end
      Color.new(*values)
    end

    def self.parse_int_array(str)
      str =~ /\[([^\]]+)\]/
      $1.split(',').map(&:strip).map(&:to_i)
    end

    def self.parse_ivec2_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/ivec2\(([^\)]+)\)/).map{ |m| m.first.split(',').map(&:strip).map(&:to_i) }
    end

    def self.parse_ivec3_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/ivec3\(([^\)]+)\)/).map{ |m| m.first.split(',').map(&:strip).map(&:to_i) }
    end

    def self.parse_ivec4_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/ivec4\(([^\)]+)\)/).map{ |m| m.first.split(',').map(&:strip).map(&:to_i) }
    end

    def self.parse_float_array(str)
      str =~ /\[([^\]]+)\]/
      $1.split(',').map(&:strip).map(&:to_f)
    end

    def self.parse_vec2_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/vec2\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f)
        Vector2.new(*values)
      }
    end

    def self.parse_vec3_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/vec3\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f)
        Vector3.new(*values)
      }
    end

    def self.parse_vec4_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/vec4\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f)
        Vector4.new(*values)
      }
    end

    def self.parse_color_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/color\(([^\)]*)\)/).map{ |m|
        values = m.first.split(',').map(&:strip)
        if values.length == 1
          values = values.map(&:to_i)
        else
          values = values.map(&:to_f)
        end
        Color.new(*values)
      }
    end

    def self.parse_mat3(str)
      str =~ /mat3\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f)
      Matrix3.new().tap { |mat| mat.set(*values) }
    end

    def self.parse_mat4(str)
      str =~ /mat4\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f)
      Matrix4.new().tap { |mat| mat.set(*values) }
    end

    def self.parse_mat3_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/mat3\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f)
        Matrix3.new().tap { |mat| mat.set(*values) }
      }
    end

    def self.parse_mat4_array(str)
      str = /\[([^\]]+)\]/.match(str)[1]
      str.scan(/mat4\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f)
        Matrix4.new().tap { |mat| mat.set(*values) }
      }
    end

    def self.parse_texture(str)
      nil
    end

    def self.parse_texture_array(str)
      []
    end

    def self.parse_uniform(uniform)
      uniform =~ UNIFORM_RGX
      type_str = $1
      type = type_str.to_sym
      is_array = type_str.end_with?('[]')
      name = $2
      value_str = $4
      value = is_array ? [] : nil
      if value_str && !value_str.empty?
        value = self.send("parse_#{type.to_s.gsub(/\[\]/, '_array')}".to_s, value_str)
      end
      [name, Uniform.new(type, value)]
    end

    def self.load_uniforms(uniforms, uniforms_lib)
      uniform_strings = nil;
      in_uniform = false

      uniforms.lines.map(&:strip).each_with_object({}) { |line, hash|
        if in_uniform
          uniform_strings << line
          if line.end_with?(';')
            in_uniform = false
            name, value = self.parse_uniform(uniform_strings.join(' '))
            hash[name] = value
          end
        elsif line =~ /#include\s+(\w+)/
          uniforms_lib[$1.to_sym].map { |(k, v)| hash[k] = v.clone }
        elsif line.start_with?('uniform')
          if line.end_with?(';')
            name, value = self.parse_uniform(line)
            hash[name] = value
          else
            in_uniform = true
            uniform_strings = [line]
          end
        end
      }
    end
  end
end
