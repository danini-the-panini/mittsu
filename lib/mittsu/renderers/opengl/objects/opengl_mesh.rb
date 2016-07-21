module Mittsu
  class OpenGLMesh < OpenGLObject3D
    def initialize(mesh, renderer)
      super
      @mesh = mesh
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

    def update
      # check all geometry groubs
      geometry = @mesh.geometry

      material = nil
      material_impl = nil
      geometry.groups.each do |geometry_group|
        # TODO: place to put this???
        # glBindVertexArray(geometry_group.vertex_array_object)
        material = buffer_material(geometry_group)
        material_impl = material.implementation(@renderer)

        custom_attributes_dirty = material.attributes && material_impl.custom_attributes_dirty?

        if geometry.vertices_need_update || geometry.morph_targets_need_update || geometry.elements_need_update || geometry.uvs_need_update || geometry.normals_need_update || geometry.colors_need_update || geometry.tangents_need_update || custom_attributes_dirty
          geometry_group.set_mesh_buffers(@mesh, GL_DYNAMIC_DRAW, !geometry.dynamic, material)
        end
      end

      geometry.vertices_need_update = false
      geometry.morph_targets_need_update = false
      geometry.elements_need_update = false
      geometry.uvs_need_update = false
      geometry.normals_need_update = false
      geometry.colors_need_update = false
      geometry.tangents_need_update = false

      material.attributes && material_impl.clear_custom_attributes(material)
    end

    def init_geometry
      @object.geometry.renderer = @renderer
      @object.geometry.init_geometry_groups(@object)
    end

    def add_opengl_object
      geometry = @object.geometry
      case geometry
      when BufferGeometry
        @renderer.add_opengl_object(geometry, @object)
      when Geometry
        geometry.groups.each do |group|
          @renderer.add_opengl_object(group, @object)
        end
      end
    end
  end
end
