module Mittsu
  class PointCloudMaterial
    def refresh_uniforms(uniforms)
      uniforms['psColor'].value = color
      uniforms['opacity'].value = opacity
      uniforms['size'].value = size
      # uniforms['scale'].value = _canvas.height / 2.0 # TODO get window height?

      uniforms['map'].value = map

      if !map.nil?
        offset = material.map.offset
        repeat = material.map.repeat

        uniforms['offsetRepeat'].value.set(offset.x, offset.y, repeat.x, repeat.y)
      end
    end

    def init_shader
      @shader = ShaderLib.create_shader(shader_id)
    end

    def shader_id
      :particle_basic
    end
  end
end
