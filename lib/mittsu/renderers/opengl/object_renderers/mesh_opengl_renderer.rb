module Mittsu
  class MeshOpenGLRenderer
    def initialize(mesh, renderer)
      @mesh = mesh
      @renderer = renderer
    end

    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      type = GL_UNSIGNED_INT # geometry_group.type_array == Uint32Array ? GL_UNSIGNED_INT : GL_UNSIGNED_SHORT

      # wireframe
      if material.wireframe
        @renderer.state.set_line_width(material.wireframe_linewidth * @pixel_ratio)

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group.line_buffer) if update_buffers
        glDrawElements(GL_LINES, geometry_group.line_count, type, 0)

      # triangles
      else
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group.face_buffer) if update_buffers
        glDrawElements(GL_TRIANGLES, geometry_group.face_count, type, 0)
      end

      @renderer.info[:render][:calls] += 1
      @renderer.info[:render][:vertices] += geometry_group.face_count
      @renderer.info[:render][:faces] += geometry_group.face_count / 3
    end
  end
end
