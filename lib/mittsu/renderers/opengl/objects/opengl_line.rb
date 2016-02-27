module Mittsu
  class OpenGLLine < OpenGLObject3D
    def initialize(line, renderer)
      super
      @line = line
      @renderer = renderer
    end

    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      mode = @line.mode == LineStrip ? GL_LINE_STRIP : GL_LINES

      @renderer.state.set_line_width(material.line_width * @renderer.pixel_ratio)

      glDrawArrays(mode, 0, geometry_group.line_count)

      @renderer.info[:render][:calls] += 1
    end

    def update
      # TODO: glBindVertexArray ???
      geometry = @line.geometry
      material = buffer_material(geometry)
      material_impl = material.implementation(@renderer)
      custom_attributes_dirty = material.attributes && material_impl.custom_attributes_dirty?

      if geometry.vertices_need_update || geometry.colors_need_update || geometry.line_distances_need_update || custom_attributes_dirty
        geometry_impl = geometry.implementation(self)
        geometry_impl.set_line_buffers(GL_DYNAMIC_DRAW)
      end

      geometry.vertices_need_update = false
      geometry.colors_need_update = false
      geometry.line_distances_need_update = false

      material.attributes && material_impl.clear_custom_attributes
    end
  end
end
