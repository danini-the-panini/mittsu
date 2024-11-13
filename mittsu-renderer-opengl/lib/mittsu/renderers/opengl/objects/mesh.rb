module Mittsu
  class Mesh
    attr_accessor :renderer

    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      type = GL::UNSIGNED_INT # geometry_group.type_array == Uint32Array ? GL::UNSIGNED_INT : GL::UNSIGNED_SHORT

      # wireframe
      if material.wireframe
        @renderer.state.set_line_width(material.wireframe_linewidth * @renderer.pixel_ratio)

        GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, geometry_group.line_buffer) if update_buffers
        GL.DrawElements(GL::LINES, geometry_group.line_count, type, 0)

      # triangles
      else
        GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, geometry_group.face_buffer) if update_buffers
        GL.DrawElements(GL::TRIANGLES, geometry_group.face_count, type, 0)
      end

      @renderer.info[:render][:calls] += 1
      @renderer.info[:render][:vertices] += geometry_group.face_count
      @renderer.info[:render][:faces] += geometry_group.face_count / 3
    end

    def update
      # check all geometry groubs
      mat = nil
      geometry.groups.each do |geometry_group|
        # TODO: place to put this???
        # GL.BindVertexArray(geometry_group.vertex_array_object)
        mat = buffer_material(geometry_group)

        custom_attributes_dirty = mat.attributes && mat.custom_attributes_dirty?

        if geometry.vertices_need_update || geometry.morph_targets_need_update || geometry.elements_need_update || geometry.uvs_need_update || geometry.normals_need_update || geometry.colors_need_update || geometry.tangents_need_update || custom_attributes_dirty
          geometry_group.set_mesh_buffers(self, GL::DYNAMIC_DRAW, !geometry.dynamic, mat)
        end
      end

      geometry.vertices_need_update = false
      geometry.morph_targets_need_update = false
      geometry.elements_need_update = false
      geometry.uvs_need_update = false
      geometry.normals_need_update = false
      geometry.colors_need_update = false
      geometry.tangents_need_update = false

      mat.attributes && mat.clear_custom_attributes
    end

    def init_geometry
      geometry.renderer = @renderer
      geometry.init_geometry_groups(self)
    end

    def add_opengl_object
      case geometry
      when BufferGeometry
        @renderer.add_opengl_object(geometry, self)
      when Geometry
        geometry.groups.each do |group|
          @renderer.add_opengl_object(group, self)
        end
      else
        raise "GEOMETRY IS NULL"
      end
    end
  end
end
