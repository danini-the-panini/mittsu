module Mittsu
  module RBSLLoader
    UNIFORM_RGX = /uniform\s+(\S+)\s+(\w+)(|\s+\=\s+(.+));/
    COLOR_RGX = /color\(([^\)]*)\)/

    class << self
      def load_shader(shader, chunks)
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

      def extract_array_contents(str)
        /\[([^\]]+)\]/.match(str)[1]
      end

      def parse_int(str)
        str.to_i
      end

      (2..4).each do |n|
        define_method("parse_ivec#{n}") do |str|
          str =~ /ivec#{n}\(([^\)]+)\)/
          $1.split(',').map(&:strip).map(&:to_i).take(n)
        end
      end

      def parse_float(str)
        str.to_f
      end

      def parse_single_color(values)
        if values.length == 1
          values = values.map(&:to_i)
        else
          values = values.map(&:to_f)
        end
        Color.new(*values)
      end

      def parse_color(str)
        str =~ COLOR_RGX
        values = $1.split(',').map(&:strip)
        parse_single_color(values)
      end

      def parse_color_array(str)
        str = extract_array_contents(str)
        str.scan(COLOR_RGX).map{ |m|
          values = m.first.split(',').map(&:strip)
          parse_single_color(values)
        }
      end

      def parse_int_array(str)
        str = extract_array_contents(str)
        str.split(',').map(&:strip).map(&:to_i)
      end

      def parse_float_array(str)
        str = extract_array_contents(str)
        str.split(',').map(&:strip).map(&:to_f)
      end

      [Vector2, Vector3, Vector4].each do |vectorClass|
        define_method("parse_vec#{vectorClass::DIMENSIONS}") do |str|
          str =~ /vec#{vectorClass::DIMENSIONS}\(([^\)]+)\)/
          values = $1.split(',').map(&:strip).map(&:to_f).take(vectorClass::DIMENSIONS)
          vectorClass.new(*values)
        end
      end

      (2..4).each do |n|
        define_method("parse_ivec#{n}_array") do |str|
          str = extract_array_contents(str)
          str.scan(/ivec#{n}\(([^\)]+)\)/).map{ |m| m.first.split(',').map(&:strip).map(&:to_i).take(n) }
        end
      end

      [Vector2, Vector3, Vector4].each do |vectorClass|
        define_method("parse_vec#{vectorClass::DIMENSIONS}_array") do |str|
          str = extract_array_contents(str)
          str.scan(/vec#{vectorClass::DIMENSIONS}\(([^\)]+)\)/).map{ |m|
            values = m.first.split(',').map(&:strip).map(&:to_f).take(vectorClass::DIMENSIONS)
            vectorClass.new(*values)
          }
        end
      end

      [Matrix3, Matrix4].each do |matrixClass|
        define_method("parse_mat#{matrixClass::DIMENSIONS}") do |str|
          str =~ /mat#{matrixClass::DIMENSIONS}\(([^\)]+)\)/
          values = $1.split(',').map(&:strip).map(&:to_f).take(matrixClass::DIMENSIONS * matrixClass::DIMENSIONS)
          matrixClass.new().tap { |mat| mat.set(*values) }
        end
      end

      [Matrix3, Matrix4].each do |matrixClass|
        define_method("parse_mat#{matrixClass::DIMENSIONS}_array") do |str|
          str = extract_array_contents(str)
          str.scan(/mat#{matrixClass::DIMENSIONS}\(([^\)]+)\)/).map{ |m|
            values = m.first.split(',').map(&:strip).map(&:to_f).take(matrixClass::DIMENSIONS * matrixClass::DIMENSIONS)
            matrixClass.new().tap { |mat| mat.set(*values) }
          }
        end
      end

      def parse_texture(_str)
        nil
      end

      def parse_texture_array(_str)
        []
      end

      def parse_uniform(uniform)
        uniform =~ UNIFORM_RGX
        type_str = $1
        type = type_str.to_sym
        is_array = type_str.end_with?('[]')
        name = $2
        value_str = $4
        value = is_array ? [] : nil
        if value_str && !value_str.empty?
          value = send("parse_#{type.to_s.gsub(/\[\]/, '_array')}".to_s, value_str)
        end
        [name, Uniform.new(type, value)]
      end

      def load_uniforms(uniforms, uniforms_lib)
        uniform_strings = nil;
        in_uniform = false

        uniforms.lines.map(&:strip).each_with_object({}) { |line, hash|
          if in_uniform
            uniform_strings << line
            if line.end_with?(';')
              in_uniform = false
              name, value = parse_uniform(uniform_strings.join(' '))
              hash[name] = value
            end
          elsif line =~ /#include\s+(\w+)/
            uniforms_lib[$1.to_sym].map { |(k, v)| hash[k] = v.clone }
          elsif line.start_with?('uniform')
            if line.end_with?(';')
              name, value = parse_uniform(line)
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
end
