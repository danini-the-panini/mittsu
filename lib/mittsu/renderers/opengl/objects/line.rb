module Mittsu
  class Line
    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      opengl_mode = mode == LineStrip ? GL_LINE_STRIP : GL_LINES

      @renderer.state.set_line_width(material.line_width * @renderer.pixel_ratio)

      glDrawArrays(opengl_mode, 0, geometry_group.line_count)

      @renderer.info[:render][:calls] += 1
    end

    def update
      # TODO: glBindVertexArray ???
      material = buffer_material(geometry)
      custom_attributes_dirty = material.attributes && material.custom_attributes_dirty?

      if geometry.vertices_need_update || geometry.colors_need_update || geometry.line_distances_need_update || custom_attributes_dirty
        geometry.set_line_buffers(GL_DYNAMIC_DRAW)
      end

      geometry.vertices_need_update = false
      geometry.colors_need_update = false
      geometry.line_distances_need_update = false

      material.attributes && material.clear_custom_attributes
    end

    def init_geometry
      geometry.renderer = @renderer
      if geometry.vertex_buffer.nil?
        geometry.create_line_buffers
        geometry.init_line_buffers(self)

        geometry.vertices_need_update = true
        geometry.colors_need_update = true
        geometry.line_distances_need_update = true
      end
    end

    def add_opengl_object
      @renderer.add_opengl_object(geometry, self)
    end
  end
end
