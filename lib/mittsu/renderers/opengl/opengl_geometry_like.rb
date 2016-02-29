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
                  :num_vertices

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

      if attributes['color'] && attributes['color'] >= 0
        update_color_buffer(attributes['color'])
      elsif !material.default_attribute_values.nil?
        glVertexAttrib3fv(attributes['color'], material.default_attribute_values.color)
      end

      if attributes['normal'] && attributes['normal'] >= 0
        update_normal_buffer(attributes['normal'])
      end

      if attributes['tangent'] && attributes['tangent'] >= 0
        update_tangent_buffer(attributes['tangent'])
      end

      if attributes['uv'] && attributes['uv'] >= 0
        if object.geometry.face_vertex_uvs[0]
          update_uv_buffer(attributes['uv'])
        elsif !material.default_attribute_values.nil?
          glVertexAttrib2fv(attributes['uv'], material.default_attribute_values.uv)
        end
      end

      if attributes['uv2'] && attributes['uv2'] >= 0
        if object.geometry.face_vertex_uvs[1]
          update_uv2_buffer(attributes['uv2'])
        elsif !material.default_attribute_values.nil?
          glVertexAttrib2fv(attributes['uv2'], material.default_attribute_values.uv2)
        end
      end

      if material.skinning && attributes['skin_index'] && attributes['skin_weight'] && attributes['skin_index'] >= 0 && attributes['skin_weight'] >= 0
        update_skin_buffers(attributes['skin_index'], attributes['skin_weight'])
      end

      if attributes['line_distances'] && attributes['line_distances'] >= 0
        update_line_distances_buffer(attributes['line_distances'])
      end
    end

    private

    def update_color_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @color_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_normal_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @normal_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_tangent_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @tangent_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 4, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_uv_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @uv_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 2, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_uv2_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @uv2_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 2, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_skin_buffers(index_attribute, weight_attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @skin_indices_buffer)
      @renderer.state.enable_attribute(index_attribute)
      glVertexAttribPointer(index_attribute, 4, GL_FLOAT, GL_FALSE, 0, 0)

      glBindBuffer(GL_ARRAY_BUFFER, @skin_weight_buffer)
      @renderer.state.enable_attribute(skin_indices_buffer)
      glVertexAttribPointer(skin_indices_buffer, 4, GL_FLOAT, GL_FALSE, 0, 0)
    end

    def update_line_distances_buffer(attribute)
      glBindBuffer(GL_ARRAY_BUFFER, @line_distance_buffer)
      @renderer.state.enable_attribute(attribute)
      glVertexAttribPointer(attribute, 1, GL_FLOAT, GL_FALSE, 0, 0)
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
      return unless belongs_to_attribute >= 0
      glBindBuffer(GL_ARRAY_BUFFER, custom_attribute.buffer)
      @state.enable_attribute(belongs_to_attribute)
      glVertexAttribPointer(belongs_to_attribute, custom_attribute.size, GL_FLOAT, GL_FALSE, 0, 0)
    end
  end
end
