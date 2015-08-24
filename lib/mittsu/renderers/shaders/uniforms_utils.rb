module Mittsu
  module UniformsUtils
    def self.merge(uniforms)
      merged = {}

      uniforms.each do |uniform|
        tmp = UniformsUtils.clone(uniform)

        next if tmp.nil?

        tmp.each do |(p, tmp_p)|
          merged[p] = tmp_p
        end
      end

      merged
    end

    def self.clone(uniforms_src)
      return if uniforms_src.nil?

      uniforms_dst = {}

      uniforms_src.each do |(u, uniform_src)|
        uniforms_dst[u] = uniform_src.clone
      end

      uniforms_dst
    end
  end
end
