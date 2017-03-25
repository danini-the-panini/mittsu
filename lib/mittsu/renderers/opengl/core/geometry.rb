require 'mittsu/renderers/opengl/opengl_geometry_like'

module Mittsu
  class Geometry
    include OpenGLGeometryLike

    attr_accessor :groups, :initted

    def init_geometry_groups(object)
      material = object.material
      add_buffers = false

      if @groups.nil? || @groups_need_update
        @renderer.remove_opengl_object(object)

        @groups = make_groups(material.is_a?(MeshFaceMaterial))

        @groups_need_update = false
      end

      # create separate VBOs per geometry chunk

      @groups.each do |geometry_group|
        # initialize VBO on the first access
        if geometry_group.vertex_buffer.nil?
          geometry_group.create_mesh_buffers
          geometry_group.init_mesh_buffers(object)

          @vertices_need_update = true
          @morph_targets_need_update = true
          @elements_need_update = true
          @uvs_need_update = true
          @normals_need_update = true
          @tangents_need_update = true
          @colors_need_update = true

          add_buffers = true
        else
          add_buffers = false
        end

        if add_buffers || !object.active?
          @renderer.add_opengl_object(geometry_group, object)
        end
      end

      object.active = true
    end

    def init_line_buffers(object)
      nvertices = @vertices.length

      @vertex_array = Float32Array.new(nvertices * 3, 0.0)
      @color_array = Float32Array.new(nvertices * 3, 0.0)
      @line_distance_array = Float32Array.new(nvertices, 0.0)

      @line_count = nvertices

      init_custom_attributes(object)
    end

    def init_particle_buffers(object)
      nvertices = @vertices.length

      @vertex_array = Float32Array.new(nvertices * 3, 0.0)
      @color_array = Float32Array.new(nvertices * 3, 0.0)

      @particle_count = nvertices

      init_custom_attributes(object)
    end

    def create_line_buffers
      @vertex_array_object = glCreateVertexArray

      @vertex_buffer = glCreateBuffer
      @color_buffer = glCreateBuffer
      @line_distance_buffer = glCreateBuffer

      @renderer.info[:memory][:geometries] += 1
    end

    def create_particle_buffers
      @vertex_array_object = glCreateVertexArray

      @vertex_buffer = glCreateBuffer
      @color_buffer = glCreateBuffer

      @renderer.info[:memory][:geometries] += 1
    end

    def set_line_buffers(hint)
      if @vertices_need_update
        @vertices.each_with_index do |vertex, v|
          offset = v * 3

          @vertex_array[offset]     = vertex.x
          @vertex_array[offset + 1] = vertex.y
          @vertex_array[offset + 2] = vertex.z
        end

        glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
        glBufferData(GL_ARRAY_BUFFER, @vertex_array.bytesize, @vertex_array.ptr, hint)
      end

      if @colors_need_update
        @colors.each_with_index do |color, c|
          offset = c * 3

          @color_array[offset]     = color.r
          @color_array[offset + 1] = color.g
          @color_array[offset + 2] = color.b
        end

        glBindBuffer(GL_ARRAY_BUFFER, @color_buffer)
        glBufferData(GL_ARRAY_BUFFER, @color_array.bytesize, @color_array.ptr, hint)
      end

      if @line_distances_need_update
        @line_distances.each_with_index do |l, d|
          @line_distance_array[d] = l
        end

        glBindBuffer(GL_ARRAY_BUFFER, @line_distance_buffer)
        glBufferData(GL_ARRAY_BUFFER, @line_distance_array.bytesize, @line_distance_array.ptr, hint)
      end

      if @custom_attributes
        @custom_attributes.each do |custom_attribute|
          offset = 0

          values = custom_attribute.value

          case custom_attribute.size
          when 1
            value.each_with_index do |value, ca|
              custom_attribute.array[ca] = value
            end
          when 2
            values.each do |value|
              custom_attribute.array[offset    ] = value.x
              custom_attribute.array[offset + 1] = value.y

              offset += 2
            end
          when 3
            if custom_attribute.type === :c
              values.each do |value|
                custom_attribute.array[offset    ] = value.r
                custom_attribute.array[offset + 1] = value.g
                custom_attribute.array[offset + 2] = value.b

                offset += 3
              end
            else
              values.each do |value|
                custom_attribute.array[offset    ] = value.x
                custom_attribute.array[offset + 1] = value.y
                custom_attribute.array[offset + 2] = value.z

                offset += 3
              end
            end
          when 4
            values.each do |value|
              custom_attribute.array[offset    ] = value.x
              custom_attribute.array[offset + 1] = value.y
              custom_attribute.array[offset + 2] = value.z
              custom_attribute.array[offset + 3] = value.w

              offset += 4
            end
          end

          glBindBuffer(GL_ARRAY_BUFFER, custom_attribute.buffer)
          glBufferData(GL_ARRAY_BUFFER, custom_attribute.array.bytesize, custom_attribute.array.ptr, hint)

          custom_attribute.needs_update = false
        end
      end
    end

    def set_particle_buffers(hint)
      if @vertices_need_update
        @vertices.each_with_index do |vertex, v|
          offset = v * 3

          @vertex_array[offset]     = vertex.x
          @vertex_array[offset + 1] = vertex.y
          @vertex_array[offset + 2] = vertex.z
        end


        glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
        glBufferData(GL_ARRAY_BUFFER, @vertex_array.bytesize, @vertex_array.ptr, hint)
      end

      if @colors_need_update
        @colors.each_with_index do |color, c|
          offset = c * 3;

          @color_array[offset]     = color.r
          @color_array[offset + 1] = color.g
          @color_array[offset + 2] = color.b
        end

        glBindBuffer(GL_ARRAY_BUFFER, @color_buffer)
        glBufferData(GL_ARRAY_BUFFER, @color_array.bytesize, @color_array.ptr, hint)
      end

      if @custom_attribute
        @custom_attributes.each do |custom_attribute|
          if custom_attribute.needs_update? && (custom_attribute.bount_to.nil? || custom_attribute.bount_to == 'vertices')
            offset = 0

            if custom_attribute.size == 1
              custom_attribute.value.each_with_index do |value, ca|
                custom_attribute.array[ca] = value
              end
            elsif custom_attribute.size == 2
              custom_attribute.value.each do |value|
                custom_attribute.array[offset]     = value.x
                custom_attribute.array[offset + 1] = value.y

                offset += 2
              end
            elsif custom_attribute.size == 3
              if custom_attribute.type == :c
                custom_attribute.value.each do |value|
                  custom_attribute.array[offset]     = value.r
                  custom_attribute.array[offset + 1] = value.g
                  custom_attribute.array[offset + 2] = value.b

                  offset += 3
                end
              else
                custom_attribute.value.each do |value|
                  custom_attribute.array[offset]     = value.x
                  custom_attribute.array[offset + 1] = value.y
                  custom_attribute.array[offset + 2] = value.z

                  offset += 3
                end
              end
            elsif custom_attribute.size == 4
              custom_attribute.value.each do |value|
                custom_attribute.array[offset]     = value.x
                custom_attribute.array[offset + 1] = value.y
                custom_attribute.array[offset + 2] = value.z
                custom_attribute.array[offset + 3] = value.w

                offset += 3
              end
            end
          end

          glBindBuffer(GL_ARRAY_BUFFER, customAttribute.buffer)
          glBufferData(GL_ARRAY_BUFFER, customAttribute.array, hint)

          custom_attribute.needs_update = false
        end
      end
    end

    private

    def make_groups(uses_face_material = false)
      max_vertices_in_group = 65535 # TODO: OES_element_index_uint ???

      hash_map = {}

      num_morph_targets = @morph_targets.length
      num_morph_normals = @morph_normals.length

      groups = {}
      groups_list = []

      @faces.each_with_index do |face, f|
        material_index = uses_face_material ? face.material_index : 0

        if !hash_map.include? material_index
          hash_map[material_index] = { hash: material_index, counter: 0 }
        end

        group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

        if !groups.include? group_hash
          group = OpenGLGeometryGroup.new(material_index, num_morph_targets, num_morph_normals, @renderer)

          groups[group_hash] = group
          groups_list << group
        end

        if groups[group_hash].num_vertices + 3 > max_vertices_in_group
          hash_map[material_index][:counter] += 1
          group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

          if !groups.include? group_hash
            group = OpenGLGeometryGroup.new(material_index, num_morph_targets, num_morph_normals, @renderer)

            groups[group_hash] = group
            groups_list << group
          end
        end
        groups[group_hash].faces3 << f
        groups[group_hash].num_vertices += 3
      end
      groups_list
    end

    def init_custom_attributes(object)
      material = object.material

      nvertices = @vertices.length

      if material.attributes
        @custom_attributes_list ||= []

        material.attributes.each do |(name, attribute)|
          if !attribute[:_opengl_initialized] || attribute.create_unique_buffers
            attribute[:_opengl_initialized] = true

            size = case attribute.type
            when :v2 then 2
            when :v3 then 3
            when :v4 then 4
            when :c then 3
            else 1
            end

            attribute.size = size

            attribute.array = Float32Array.new(nvertices * size)

            attribute.buffer = glCreateBuffer
            attribute.buffer.belongs_to_attribute = name

            attribute.needs_update = true
          end

          @custom_attributes_list << attribute
        end
      end
    end
  end
end
