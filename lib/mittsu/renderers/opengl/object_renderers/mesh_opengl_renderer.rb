module Mittsu
  class MeshOpenGLRenderer
    def initialize(mesh, renderer)
      @mesh = mesh
      @renderer = renderer
    end

    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      type = GL_UNSIGNED_INT # geometry_group[:_type_array] == Uint32Array ? GL_UNSIGNED_INT : GL_UNSIGNED_SHORT

      # wireframe
      if material.wireframe
        @renderer.state.set_line_width(material.wireframe_linewidth * @pixel_ratio)

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group[:_opengl_line_buffer]) if update_buffers
        glDrawElements(GL_LINES, geometry_group[:_opengl_line_count], type, 0)

      # triangles
      else
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, geometry_group[:_opengl_face_buffer]) if update_buffers
        glDrawElements(GL_TRIANGLES, geometry_group[:_opengl_face_count], type, 0)
      end

      @renderer.info[:render][:calls] += 1
      @renderer.info[:render][:vertices] += geometry_group[:_opengl_face_count]
      @renderer.info[:render][:faces] += geometry_group[:_opengl_face_count] / 3
    end
  end
end
