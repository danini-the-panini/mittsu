module Mittsu
  class PointCloud
    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      glDrawArrays(GL_POINTS, 0, geometry_group.particle_count)

      @renderer.info[:render][:calls] += 1
      @renderer.info[:render][:points] += geometry_group.particle_count
    end

    def update
			material = buffer_material(geometry)
			custom_attributes_dirty = material.attributes &&  material.custom_attributes_dirty?

			if geometry.vertices_need_update || geometry.colors_need_update || custom_attributes_dirty
				geometry.set_particle_buffers(GL_DYNAMIC_DRAW)
			end

			geometry.vertices_need_update = false
			geometry.colors_need_update = false

      material.attributes && material.clear_custom_attributes
    end

    def init_geometry
      geometry.renderer = @renderer
      if geometry.vertex_buffer.nil?
        geometry.create_particle_buffers
        geometry.init_particle_buffers(self)

        geometry.vertices_need_update = true
        geometry.colors_need_update = true
      end
    end

    def add_opengl_object
      @renderer.add_opengl_object(geometry, self)
    end
  end
end
