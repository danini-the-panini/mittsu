module Mittsu
  class Object3D
    attr_accessor :morph_target_influences, :renderer, :initted
    attr_reader :model_view_matrix
    attr_writer :active

    def active?
      @active
    end

    def init
      if !@initted
        puts " --- INIT #{self.name}" if DEBUG

        @initted = true
        @model_view_matrix = Matrix4.new
        @normal_matrix = Matrix3.new

        add_event_listener(:removed, @renderer.method(:on_object_removed))
      end

      if geometry.nil?
        # ImmediateRenderObject
      else
        if !geometry.initted
          geometry.initted = true
          geometry.add_event_listener(:dispose, @renderer.method(:on_geometry_dispose))
          if geometry.is_a?(BufferGeometry)
            @renderer.info[:memory][:geometries] += 1
          else
            init_geometry
          end
          # TODO: when PointCloud exists
          # when PointCloud
          #   if geometry[:_opengl_vertex_buffer].nil?
          #     create_particle_buffers(geometry)
          #     init_particle_buffers(geometry, object)
          #
          #     geometry.vertices_need_update = true
          #     geometry.colors_need_update = true
          #   end
        end
      end

      if !@active
        @active = true

        add_opengl_object
        # TODO: when ImmediateRenderObject exists
        # if object.is_a? ImmediateRenderObject || object.immediate_render_callback
        #   add_buffer_immediate(@renderer.instance_variable_get(:@_opengl_objects_immediate), self)
        # end
      end
    end

    def project(renderer)
      puts " --- PROJECT #{self.name}" if DEBUG
      @renderer = renderer
      return unless visible
      init

      # TODO!!! FIXME!!!
      opengl_objects = @renderer.instance_variable_get(:@_opengl_objects)[id]

      if opengl_objects && (!frustum_culled || @renderer.object_in_frustum?(self))
        opengl_objects.each do |opengl_object|
          # TODO!!! FIXME!!!
          @renderer.send(:unroll_buffer_material, opengl_object)

          opengl_object.render = true
          if @renderer.sort_objects?
            @_vector3 ||= Vector3.new

            @_vector3.set_from_matrix_position(matrix_world)
            @_vector3.apply_projection(@renderer.proj_screen_matrix)

            opengl_object[:z] = @_vector3.z
          end
        end
      end

      project_children
    end

    def setup_matrices(camera)
      @model_view_matrix.multiply_matrices(camera.matrix_world_inverse, matrix_world)
      @normal_matrix.normal_matrix(@model_view_matrix)
      @model_view_matrix
    end

    def load_uniforms_matrices(uniforms)
      GL.UniformMatrix4fv(uniforms['modelViewMatrix'],
                         1, GL::FALSE,
                         array_to_ptr_easy(@model_view_matrix.elements))

      if uniforms['normalMatrix']
        GL.UniformMatrix3fv(uniforms['normalMatrix'],
                           1, GL::FALSE,
                           array_to_ptr_easy(@normal_matrix.elements))
      end
    end

    def buffer_material(geometry_group)
      if material.is_a?(MeshFaceMaterial)
        material.materials[geometry_group.material_index]
      else
        material
      end
    end

    def init_geometry
      # NOOP
    end

    def add_opengl_object
      # NOOP
    end

    def deinit
      @initted = nil
      @model_view_matrix = nil
      @normal_matrix = nil
      @active = nil
    end

    protected

    def project_children
      children.each do |child|
        child.project(@renderer)
      end
    end
  end
end
