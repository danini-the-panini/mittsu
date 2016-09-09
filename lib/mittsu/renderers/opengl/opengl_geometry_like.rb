module Mittsu
  module OpenGLGeometryLike
    CONST_BUFFER_NAMES = [
      :vertex,
      :color,
      :normal,
      :tangent,
      :uv,
      :uv2,
      :skin_indices,
      :skin_weight,
      :line_distance,
      :face,
      :line
    ]
    attr_accessor(*CONST_BUFFER_NAMES.map(&:to_s).map { |name| "#{name}_buffer" }.map(&:to_sym))
    attr_accessor(*CONST_BUFFER_NAMES.map(&:to_s).map { |name| "#{name}_array" }.map(&:to_sym))

    attr_accessor :vertex_array_object,
                  :num_morph_targets,
                  :num_morph_normals,
                  :morph_targets_buffers,
                  :morph_normals_buffers,
                  :morph_targets_arrays,
                  :morph_normals_arrays,
                  :faces3,
                  :type_array,
                  :face_count,
                  :line_count,
                  :initted_arrays,
                  :custom_attributes_list,
                  :num_vertices,
                  :renderer

    def bind_vertex_array_object
      glBindVertexArray(@vertex_array_object) if @vertex_array_object
    end

    def update_vertex_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_other_buffers(object, material, attributes)
      update_custom_attributes(attributes)

      update_color_buffer(attributes['color'], object, material)
      update_normal_buffer(attributes['normal'])
      update_tangent_buffer(attributes['tangent'])
      update_uv_buffers(attributes['uv'], attributes['uv2'], object, material)

      if material.skinning
        update_skin_buffers(attributes['skin_index'], attributes['skin_weight'])
      end

      update_line_distances_buffer(attributes['line_distances'])
    end

    private

    def attribute_exists?(attribute)
      attribute && attribute >= 0
    end

    def update_color_buffer(attribute, object, material)
      return unless attribute_exists?(attribute)
      if object.geometry.colors.length > 0 || object.geometry.faces.length > 0
        update_attribute(attribute, @color_buffer, 3)
      elsif material.default_attribute_values
        glVertexAttrib3fv(attribute, material.default_attribute_values.color)
      end
    end

    def update_normal_buffer(attribute)
      return unless attribute_exists?(attribute)
      update_attribute(attribute, @normal_buffer, 3)
    end

    def update_tangent_buffer(attribute)
      return unless attribute_exists?(attribute)
      update_attribute(attribute, @tangent_buffer, 4)
    end

    def update_uv_buffers(uv_attribute, uv2_attribute, object, material)
      update_uv_buffer(uv_attribute, @uv_buffer, object, 0)
      update_uv_buffer(uv2_attribute, @uv2_buffer, object, 1)
    end

    def update_uv_buffer(attribute, buffer, object, index)
      return unless attribute_exists?(attribute)
      if object.geometry.face_vertex_uvs[index]
        update_attribute(attribute, buffer, 2)
      else
        # TODO default_attribute_value ???
        # glVertexAttrib2fv(attribute, default_attribute_value)
      end
    end

    def update_skin_buffers(index_attribute, weight_attribute)
      return unless attribute_exists?(index_attribute) && attribute_exists?(weight_attribute)
      update_attribute(attribute, @skin_indices_buffer, 4)
      update_attribute(attribute, @skin_weight_buffer, 4)
    end

    def update_line_distances_buffer(attribute)
      return unless attribute_exists?(attribute)
      update_attribute(attribute, @line_distance_buffer, 1)
    end

    def update_custom_attributes(attributes)
      if @custom_attributes_list
        @custom_attributes_list.each do |custom_attribute|
          belongs_to_attribute = attributes[custom_attribute.buffer.belongs_to_attribute]
          update_custom_attribute(custom_attribute, belongs_to_attribute)
        end
      end
    end

    def update_custom_attribute(custom_attribute, belongs_to_attribute)
      return unless attribute_exists?(belongs_to_attribute)
      update_attribute(attribute, custom_attribute.buffer, custom_attribute.size)
    end

    def update_attribute(attribute, buffer, size)
      glBindBuffer(GL_ARRAY_BUFFER, buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, size, GL_FLOAT, GL_FALSE, 0, 0)
    end
  end
end
