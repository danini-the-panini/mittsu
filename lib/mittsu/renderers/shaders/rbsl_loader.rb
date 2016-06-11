module Mittsu
  module RBSLLoader
    UNIFORM_RGX = /uniform\s+(\S+)\s+(\w+)(|\s+\=\s+(.+));/
    COLOR_RGX = /color\(([^\)]*)\)/

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

    def self.extract_array_contents(str)
      /\[([^\]]+)\]/.match(str)[1]
    end

    def self.parse_int(str)
      str.to_i
    end

    def self.parse_ivec(str, n)
      str =~ /ivec#{n}\(([^\)]+)\)/
      $1.split(',').map(&:strip).map(&:to_i).take(n)
    end

    def self.parse_ivec2(str)
      self.parse_ivec(str, 2)
    end

    def self.parse_ivec3(str)
      self.parse_ivec(str, 3)
    end

    def self.parse_ivec4(str)
      self.parse_ivec(str, 4)
    end

    def self.parse_float(str)
      str.to_f
    end

    def self.parse_vec(str, vectorClass)
      str =~ /vec#{vectorClass::DIMENSIONS}\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f).take(vectorClass::DIMENSIONS)
      vectorClass.new(*values)
    end

    def self.parse_vec2(str)
      self.parse_vec(str, Vector2)
    end

    def self.parse_vec3(str)
      self.parse_vec(str, Vector3)
    end

    def self.parse_vec4(str)
      self.parse_vec(str, Vector4)
    end

    def self.parse_single_color(values)
      if values.length == 1
        values = values.map(&:to_i)
      else
        values = values.map(&:to_f)
      end
      Color.new(*values)
    end

    def self.parse_color(str)
      str =~ COLOR_RGX
      values = $1.split(',').map(&:strip)
      self.parse_single_color(values)
    end

    def self.parse_color_array(str)
      str = self.extract_array_contents(str)
      str.scan(COLOR_RGX).map{ |m|
        values = m.first.split(',').map(&:strip)
        self.parse_single_color(values)
      }
    end

    def self.parse_int_array(str)
      str = self.extract_array_contents(str)
      str.split(',').map(&:strip).map(&:to_i)
    end

    def self.parse_ivec_array(str, n)
      str = self.extract_array_contents(str)
      str.scan(/ivec#{n}\(([^\)]+)\)/).map{ |m| m.first.split(',').map(&:strip).map(&:to_i).take(n) }
    end

    def self.parse_ivec2_array(str)
      self.parse_ivec_array(str, 2)
    end

    def self.parse_ivec3_array(str)
      self.parse_ivec_array(str, 3)
    end

    def self.parse_ivec4_array(str)
      self.parse_ivec_array(str, 4)
    end

    def self.parse_float_array(str)
      str = self.extract_array_contents(str)
      str.split(',').map(&:strip).map(&:to_f)
    end

    def self.parse_vec_array(str, vectorClass)
      str = self.extract_array_contents(str)
      str.scan(/vec#{vectorClass::DIMENSIONS}\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f).take(vectorClass::DIMENSIONS)
        vectorClass.new(*values)
      }
    end

    def self.parse_vec2_array(str)
      self.parse_vec_array(str, Vector2)
    end

    def self.parse_vec3_array(str)
      self.parse_vec_array(str, Vector3)
    end

    def self.parse_vec4_array(str)
      self.parse_vec_array(str, Vector4)
    end

    def self.parse_mat(str, matrixClass)
      str =~ /mat#{matrixClass::DIMENSIONS}\(([^\)]+)\)/
      values = $1.split(',').map(&:strip).map(&:to_f).take(matrixClass::DIMENSIONS * matrixClass::DIMENSIONS)
      matrixClass.new().tap { |mat| mat.set(*values) }
    end

    def self.parse_mat3(str)
      self.parse_mat(str, Matrix3)
    end

    def self.parse_mat4(str)
      self.parse_mat(str, Matrix4)
    end

    def self.parse_mat_array(str, matrixClass)
      str = self.extract_array_contents(str)
      str.scan(/mat#{matrixClass::DIMENSIONS}\(([^\)]+)\)/).map{ |m|
        values = m.first.split(',').map(&:strip).map(&:to_f).take(matrixClass::DIMENSIONS * matrixClass::DIMENSIONS)
        matrixClass.new().tap { |mat| mat.set(*values) }
      }
    end

    def self.parse_mat3_array(str)
      self.parse_mat_array(str, Matrix3)
    end

    def self.parse_mat4_array(str)
      self.parse_mat_array(str, Matrix4)
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
