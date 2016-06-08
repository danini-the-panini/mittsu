module Mittsu
  module RBSLLoader
    def self.load_shader(shader, chunks)
      shader.lines.flat_map(&:chomp).map{ |line|
        if line =~ /(\s*)#rb_include\s+(\w+)/
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

    def self.load_uniforms(uniforms, uniforms_lib)
      uniforms.lines.map(&:strip).map{ |line|
        if line =~ /#rb_include\s+(\w+)/
          uniforms_lib[$1.to_sym]
        end
      }.compact
    end
  end
end
