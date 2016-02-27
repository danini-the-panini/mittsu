module Mittsu
  class OpenGLObject3D
    attr_reader :model_view_matrix
    attr_writer :active

    def initialize(object, renderer)
      @object = object
      @renderer = renderer
    end

    def active?
      @active
    end

    def init
      if !@initted
        @initted = true
        @model_view_matrix = Matrix4.new
        @normal_matrix = Matrix3.new

        # @object.add_event_listener(:removed, @on_object_removed)
      end

      geometry = @object.geometry

      if geometry.nil?
        # ImmediateRenderObject
      elsif geometry[:_opengl_init].nil?
        geometry[:_opengl_init] = true
        geometry_impl = geometry.implementation(@renderer)
        # geometry.add_event_listener(:dispose, @on_geometry_dispose)
        case @object
        when BufferGeometry
          @info[:memory][:geometries] += 1
        when Mesh
          geometry_impl.init_geometry_groups(@object)
        when Line
          if geometry_impl.vertex_buffer.nil?
            # TODO!!!
            @renderer.send(:create_line_buffers, geometry_impl)
            @renderer.send(:init_line_buffers, geometry, @object)

            geometry.vertices_need_update = true
            geometry.colors_need_update = true
            geometry.line_distances_need_update
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
        case @object
        when Mesh
          case geometry
          when BufferGeometry
            # TODO!!!
            @renderer.send(:add_buffer, @renderer.instance_variable_get(:@_opengl_objects), geometry, @object)
          when Geometry
            geometry_impl = geometry.implementation(self)
            geometry_impl.groups.each do |group|
            # TODO!!!
              @renderer.send(:add_buffer, @renderer.instance_variable_get(:@_opengl_objects), group, @object)
            end
          end
        when Line #, PointCloud TODO
            # TODO!!!
          @renderer.send(:add_buffer, @renderer.instance_variable_get(:@_opengl_objects), geometry, @object)
        else
          # TODO: when ImmediateRenderObject exists
          # if object.is_a? ImmediateRenderObject || object.immediate_render_callback
          #   add_buffer_immediate(@renderer.instance_variable_get(:@_opengl_objects_immediate), @object)
          # end
        end
      end
    end

    def setup_matrices(camera)
      @model_view_matrix.multiply_matrices(camera.matrix_world_inverse, @object.matrix_world)
      @normal_matrix.normal_matrix(@model_view_matrix)
      @model_view_matrix
    end

    def load_uniforms_matrices(uniforms)
      glUniformMatrix4fv(uniforms['modelViewMatrix'],
                         1, GL_FALSE,
                         array_to_ptr_easy(@model_view_matrix.elements))

      if uniforms['normalMatrix']
        glUniformMatrix3fv(uniforms['normalMatrix'],
                           1, GL_FALSE,
                           array_to_ptr_easy(@normal_matrix.elements))
      end
    end
  end
end
