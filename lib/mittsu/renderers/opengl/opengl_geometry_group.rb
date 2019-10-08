require 'mittsu/renderers/opengl/opengl_geometry_like'

module Mittsu
  class OpenGLGeometryGroup
    include OpenGLGeometryLike

    attr_reader :id, :material_index

    alias :initted_arrays? :initted_arrays

    def initialize material_index, num_morph_targets, num_morph_normals, renderer
      @id = (@@id ||= 1).tap { @@id += 1 }

      @faces3 = []
      @num_vertices = 0

      @material_index = material_index

      @num_morph_targets = num_morph_targets
      @num_morph_normals = num_morph_normals

      @renderer = renderer
      @custom_attributes_list = []
    end

    def create_mesh_buffers
      @vertex_array_object = glCreateVertexArray

      @vertex_buffer = glCreateBuffer
      @normal_buffer = glCreateBuffer
      @tangent_buffer = glCreateBuffer
      @color_buffer = glCreateBuffer
      @uv_buffer = glCreateBuffer
      @uv2_buffer = glCreateBuffer

      @skin_indices_buffer = glCreateBuffer
      @skin_weights_buffer = glCreateBuffer

      @face_buffer = glCreateBuffer
      @line_buffer = glCreateBuffer

      if !@num_morph_targets.nil?
        @morph_targets_buffers = []

        @num_morph_targets.times do |m|
          @morph_targets_buffers << glCreateBuffer
        end
      end

      if !@num_morph_normals.nil?
        @morph_normals_buffers = []

        @num_morph_normals.times do |m|
          @morph_normals_buffers << glCreateBuffer
        end
      end
    end

    def init_mesh_buffers(object)
      geometry = object.geometry

      nvertices = @faces3.length * 3
      nvertices2 = nvertices * 2
      nvertices3 = nvertices * 3
      nvertices4 = nvertices * 4
      ntris = @faces3.length * 1
      nlines = @faces3.length * 3

      material = object.buffer_material(self)

      @vertex_array = Array.new(nvertices3) # Float32Array
      @normal_array = Array.new(nvertices3) # Float32Array
      @color_array = Array.new(nvertices3) # Float32Array
      @uv_array = Array.new(nvertices2) # Float32Array

      if geometry.face_vertex_uvs.length > 1
        @uv2_array = Array.new(nvertices2) # Float32Array
      end

      if geometry.has_tangents
        @tangent_array = Array.new(nvertices4) # Float32Array
      end

      if !object.geometry.skin_weights.empty? && !object.geometry.skin_indices.empty?
        @skin_indices_array = Array.new(nvertices4) # Float32Array
        @skin_weight_array = Array.new(nvertices4)
      end

      # UintArray from OES_element_index_uint ???

      @type_array = Array # UintArray ???
      @face_array = Array.new(ntris * 3)
      @line_array = Array.new(nlines * 2)

      num_morph_targets = @num_morph_targets

      if !num_morph_targets.zero?
        @morph_targets_arrays = []

        num_morph_targets.times do |m|
          @morph_targets_arrays << Array.new(nvertices3) # Float32Array ???
        end
      end

      num_morph_normals = @num_morph_normals

      if !num_morph_targets.zero?
        @morph_normals_arrays = []

        num_morph_normals.times do |m|
          @morph_normals_arrays << Array.new(nvertices3) # Float32Array ???
        end
      end

      @face_count = ntris * 3
      @line_count = nlines * 2

      # custom attributes

      if material.attributes
        if @custom_attributes_list.nil?
          @custom_attributes_list = []
        end

        material.attributes.each do |(name, original_attribute)|
          attribute = {}
          original_attribute.each do |(key, value)|
            attribute[key] = value
          end

          if !attribute[:_opengl_initialized] || attribute[:create_unique_buffers]
            attribute[:_opengl_initialized] = true

            size = case attribute[:type]
            when :v2 then 2
            when :v3, :c then 3
            when :v4 then 4
            else 1 # :f and :i
            end

            attribute[:size] = size
            attribute[:array] = Array.new(nvertices * size) # Float32Array

            attribute[:buffer] = glCreateBuffer
            attribute[:buffer_belongs_to_attribute] = name

            original_attribute[:needs_update] = true
            attribute[:_original] = original_attribute
          end

          @custom_attributes_list << attribute
        end
      end

      @initted_arrays = true
    end

    def set_mesh_buffers(object, hint, should_dispose, material)
      return unless @initted_arrays

      geometry = object.geometry

      needs_face_normals = material.needs_face_normals?

      vertex_index = 0

      offset = 0
      offset_uv = 0
      offset_uv2 = 0
      offset_face = 0
      offset_normal = 0
      offset_tangent = 0
      offset_line = 0
      offset_color = 0
      offset_skin = 0
      offset_morph_target = 0
      offset_custom = 0

      vertices = geometry.vertices
      obj_faces = geometry.faces

      obj_uvs = geometry.face_vertex_uvs[0]
      obj_uvs2 = geometry.face_vertex_uvs[1]

      obj_skin_indices = geometry.skin_indices
      obj_skin_weights = geometry.skin_weights

      morph_targets = geometry.morph_targets
      morph_normals = geometry.morph_normals

      if geometry.vertices_need_update
        @faces3.each do |chf|
          face = obj_faces[chf]

          v1 = vertices[face.a]
          v2 = vertices[face.b]
          v3 = vertices[face.c]

          @vertex_array[offset]     = v1.x
          @vertex_array[offset + 1] = v1.y
          @vertex_array[offset + 2] = v1.z

          @vertex_array[offset + 3] = v2.x
          @vertex_array[offset + 4] = v2.y
          @vertex_array[offset + 5] = v2.z

          @vertex_array[offset + 6] = v3.x
          @vertex_array[offset + 7] = v3.y
          @vertex_array[offset + 8] = v3.z

          offset += 9
        end

        glBindBuffer(GL_ARRAY_BUFFER, @vertex_buffer)
        glBufferData_easy(GL_ARRAY_BUFFER, @vertex_array, hint)
      end

      if geometry.morph_targets_need_update
        morph_targets.each_index do |vk|
          @faces3.each do |chf|
            face = obj_faces[chf]

            # morph positions

            v1 = morph_targets[vk].vertices[face.a]
            v2 = morph_targets[vk].vertices[face.b]
            v3 = morph_targets[vk].vertices[face.c]

            vka = @morph_targets_arrays[vk]

            vka[offset_morph_target]     = v1.x
            vka[offset_morph_target + 1] = v1.y
            vka[offset_morph_target + 2] = v1.z

            vka[offset_morph_target + 3] = v2.x
            vka[offset_morph_target + 4] = v2.y
            vka[offset_morph_target + 5] = v2.z

            vka[offset_morph_target + 6] = v3.x
            vka[offset_morph_target + 7] = v3.y
            vka[offset_morph_target + 8] = v3.z

            # morph normals

            if material.morph_normals
              if needs_face_normals
                n1 = morph_normals[vk].face_normals[chf]
                n2 = n1
                n3 = n1
              else
                face_vertex_normals = morph_normals[vk].vertex_normals[chf]

                n1 = face_vertex_normals.a
                n2 = face_vertex_normals.b
                n3 = face_vertex_normals.c
              end

              nka = @morph_normals_arrays[vk]

              nka[offset_morph_target]     = n1.x
              nka[offset_morph_target + 1] = n1.y
              nka[offset_morph_target + 2] = n1.z

              nka[offset_morph_target + 3] = n2.x
              nka[offset_morph_target + 4] = n2.y
              nka[offset_morph_target + 5] = n2.z

              nka[offset_morph_target + 6] = n3.x
              nka[offset_morph_target + 7] = n3.y
              nka[offset_morph_target + 8] = n3.z
            end

            #

            offset_morph_target += 9
          end

          glBindBuffer(GL_ARRAY_BUFFER, @morph_targets_buffers[vk])
          glBufferData_easy(GL_ARRAY_BUFFER, @morph_targets_arrays[vk], hint)

          if material.morph_normals
            glBindBuffer(GL_ARRAY_BUFFER, @morph_normals_buffers[vk])
            glBufferData_easy(GL_ARRAY_BUFFER, @morph_normals_arrays[vk], hint)
          end
        end
      end

      if !obj_skin_weights.empty?
        @faces3.each do |chf|
          face = obj_faces[chf]

          # weights

          sw1 = obj_skin_weights[face.a]
          sw2 = obj_skin_weights[face.b]
          sw3 = obj_skin_weights[face.c]

          @skin_weight_array[offset_skin]     = sw1.x
          @skin_weight_array[offset_skin + 1] = sw1.y
          @skin_weight_array[offset_skin + 2] = sw1.z
          @skin_weight_array[offset_skin + 3] = sw1.w

          @skin_weight_array[offset_skin + 4] = sw2.x
          @skin_weight_array[offset_skin + 5] = sw2.y
          @skin_weight_array[offset_skin + 6] = sw2.z
          @skin_weight_array[offset_skin + 7] = sw2.w

          @skin_weight_array[offset_skin + 8]  = sw3.x
          @skin_weight_array[offset_skin + 9]  = sw3.y
          @skin_weight_array[offset_skin + 10] = sw3.z
          @skin_weight_array[offset_skin + 11] = sw3.w

          # indices

          si1 = obj_skin_indices[face.a]
          si2 = obj_skin_indices[face.b]
          si3 = obj_skin_indices[face.c]

          @skin_indices_array[offset_skin]     = si1.x
          @skin_indices_array[offset_skin + 1] = si1.y
          @skin_indices_array[offset_skin + 2] = si1.z
          @skin_indices_array[offset_skin + 3] = si1.w

          @skin_indices_array[offset_skin + 4] = si2.x
          @skin_indices_array[offset_skin + 5] = si2.y
          @skin_indices_array[offset_skin + 6] = si2.z
          @skin_indices_array[offset_skin + 7] = si2.w

          @skin_indices_array[offset_skin + 8]  = si3.x
          @skin_indices_array[offset_skin + 9]  = si3.y
          @skin_indices_array[offset_skin + 10] = si3.z
          @skin_indices_array[offset_skin + 11] = si3.w

          offset_skin += 12
        end

        if offset_skin > 0
          glBindBuffer(GL_ARRAY_BUFFER, @skin_indices_buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, @skin_indices_array, hint)

          glBindBuffer(GL_ARRAY_BUFFER, @skin_weights_buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, @skin_weight_array, hint)
        end
      end

      if geometry.colors_need_update
        @faces3.each do |chf|
          face = obj_faces[chf]

          face_vertex_colors = face.vertex_colors
          face_color = face.color

          if face_vertex_colors.length == 3 && material.vertex_colors == VertexColors
            c1 = face_vertex_colors[0]
            c2 = face_vertex_colors[1]
            c3 = face_vertex_colors[2]
          else
            c1 = face_color
            c2 = face_color
            c3 = face_color
          end

          @color_array[offset_color]     = c1.r
          @color_array[offset_color + 1] = c1.g
          @color_array[offset_color + 2] = c1.b

          @color_array[offset_color + 3] = c2.r
          @color_array[offset_color + 4] = c2.g
          @color_array[offset_color + 5] = c2.b

          @color_array[offset_color + 6] = c3.r
          @color_array[offset_color + 7] = c3.g
          @color_array[offset_color + 8] = c3.b

          offset_color += 9
        end

        if offset_color > 0
          glBindBuffer(GL_ARRAY_BUFFER, @color_buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, @color_array, hint)
        end
      end

      if geometry.tangents_need_update && geometry.has_tangents
        @faces3.each do |chf|
          face = obj_faces[chf]

          face_vertex_tangents = face.vertex_tangents

          t1 = face_vertex_tangents[0]
          t2 = face_vertex_tangents[1]
          t3 = face_vertex_tangents[2]

          @tangent_array[offset_tangent]     = t1.x
          @tangent_array[offset_tangent + 1] = t1.y
          @tangent_array[offset_tangent + 2] = t1.z
          @tangent_array[offset_tangent + 3] = t1.w

          @tangent_array[offset_tangent + 4] = t2.x
          @tangent_array[offset_tangent + 5] = t2.y
          @tangent_array[offset_tangent + 6] = t2.z
          @tangent_array[offset_tangent + 7] = t2.w

          @tangent_array[offset_tangent + 8]  = t3.x
          @tangent_array[offset_tangent + 9]  = t3.y
          @tangent_array[offset_tangent + 10] = t3.z
          @tangent_array[offset_tangent + 11] = t3.w

          offset_tangent += 12
        end

        glBindBuffer(GL_ARRAY_BUFFER, @angent_buffer)
        glBufferData_easy(GL_ARRAY_BUFFER, @tangent_array, hint)
      end

      if geometry.normals_need_update
        @faces3.each do |chf|
          face = obj_faces[chf]

          face_vertex_normals = face.vertex_normals
          face_normal = face.normal

          if face_vertex_normals.length == 3 && !needs_face_normals
            3.times do |i|
              vn = face_vertex_normals[i]

              @normal_array[offset_normal]     = vn.x
              @normal_array[offset_normal + 1] = vn.y
              @normal_array[offset_normal + 2] = vn.z

              offset_normal += 3
            end
          else
            3.times do |i|
              @normal_array[offset_normal]     = face_normal.x
              @normal_array[offset_normal + 1] = face_normal.y
              @normal_array[offset_normal + 2] = face_normal.z

              offset_normal += 3
            end
          end
        end

        glBindBuffer(GL_ARRAY_BUFFER, @normal_buffer)
        glBufferData_easy(GL_ARRAY_BUFFER, @normal_array, hint)
      end

      if geometry.uvs_need_update && obj_uvs
        @faces3.each do |fi|
          uv = obj_uvs[fi]

          next if uv.nil?

          3.times do |i|
            uvi = uv[i]

            @uv_array[offset_uv]     = uvi.x
            @uv_array[offset_uv + 1] = uvi.y

            offset_uv += 2
          end
        end

        if offset_uv > 0
          glBindBuffer(GL_ARRAY_BUFFER, @uv_buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, @uv_array, hint)
        end
      end

      if geometry.uvs_need_update && obj_uvs2
        @faces3.each do |fi|
          uv2 = obj_uvs2[fi]

          next if uv2.nil?

          3.times do |i|
            uv2i = uv2[i]

            @uv2_array[offset_uv2]     = uv2i.x
            @uv2_array[offset_uv2 + 1] = uv2i.y

            offset_uv2 += 2
          end
        end

        if offset_uv2 > 0
          glBindBuffer(GL_ARRAY_BUFFER, @uv2_buffer)
          glBufferData_easy(GL_ARRAY_BUFFER, @uv2_array, hint)
        end
      end

      if geometry.elements_need_update
        @faces3.each do |chf|
          @face_array[offset_face]     = vertex_index
          @face_array[offset_face + 1] = vertex_index + 1
          @face_array[offset_face + 2] = vertex_index + 2

          offset_face += 3

          @line_array[offset_line]     = vertex_index
          @line_array[offset_line + 1] = vertex_index + 1

          @line_array[offset_line + 2] = vertex_index
          @line_array[offset_line + 3] = vertex_index + 2

          @line_array[offset_line + 4] = vertex_index + 1
          @line_array[offset_line + 5] = vertex_index + 2

          offset_line += 6

          vertex_index += 3
        end

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @face_buffer)
        glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, @face_array, hint)

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, @line_buffer)
        glBufferData_easy(GL_ELEMENT_ARRAY_BUFFER, @line_array, hint)
      end

      if @custom_attributes_list
        @custom_attributes_list.each do |custom_attribute|
          next if !custom_attribute[:_original][:needs_update]

          offset_custom = 0

          if custom_attribute[:size] == 1
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              @faces3.each do |chf|
                face = obj_faces[chf]

                custom_attribute[:array][offset_custom]     = custom_attribute[:value][face.a]
                custom_attribute[:array][offset_custom + 1] = custom_attribute[:value][face.b]
                custom_attribute[:array][offset_custom + 2] = custom_attribute[:value][face.c]

                offset_custom += 3
              end
            elsif custom_attribute[:bound_to] == :faces
              value = custom_attribute[:value][chf]

              custom_attribute[:array][offset_custom]     = value
              custom_attribute[:array][offset_custom + 1] = value
              custom_attribute[:array][offset_custom + 2] = value

              offset_custom += 3
            end
          elsif custom_attribute[:size] == 2
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              @faces3.each do |chf|
                face = obj_faces[chf]

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                custom_attribute[:array][offset_custom]     = v1.x
                custom_attribute[:array][offset_custom + 1] = v1.y

                custom_attribute[:array][offset_custom + 2] = v2.x
                custom_attribute[:array][offset_custom + 3] = v2.y

                custom_attribute[:array][offset_custom + 4] = v3.x
                custom_attribute[:array][offset_custom + 5] = v3.y

                offset_custom += 6
              end
            elsif custom_attribute[:bound_to] == :faces
              @faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                custom_attribute[:array][offset_custom]     = v1.x
                custom_attribute[:array][offset_custom + 1] = v1.y

                custom_attribute[:array][offset_custom + 2] = v2.x
                custom_attribute[:array][offset_custom + 3] = v2.y

                custom_attribute[:array][offset_custom + 4] = v3.x
                custom_attribute[:array][offset_custom + 5] = v3.y

                offset_custom += 6
              end
            end
          elsif custom_attribute[:size] == 3
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              @faces3.each do |chf|
                face = obj_faces[chf];

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            elsif custom_attribute[:bound_to] == :faces
              @faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            elsif custom_attribute[:bound_to] == :face_vertices
              @faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value[0]
                v2 = value[1]
                v3 = value[2]

                custom_attribute[:array][offset_custom]     = v1[0]
                custom_attribute[:array][offset_custom + 1] = v1[1]
                custom_attribute[:array][offset_custom + 2] = v1[2]

                custom_attribute[:array][offset_custom + 3] = v2[0]
                custom_attribute[:array][offset_custom + 4] = v2[1]
                custom_attribute[:array][offset_custom + 5] = v2[2]

                custom_attribute[:array][offset_custom + 6] = v3[0]
                custom_attribute[:array][offset_custom + 7] = v3[1]
                custom_attribute[:array][offset_custom + 8] = v3[2]

                offset_custom += 9
              end
            end
          elsif custom_attribute[:size] == 4
            if custom_attribute[:bound_to].nil? || custom_attribute[:bound_to] == :vertices
              @faces3.each do |chf|
                face = obj_faces[chf]

                v1 = custom_attribute[:value][face.a]
                v2 = custom_attribute[:value][face.b]
                v3 = custom_attribute[:value][face.c]

                custom_attribute[:array][offset_custom]      = v1.x
                custom_attribute[:array][offset_custom + 1 ] = v1.y
                custom_attribute[:array][offset_custom + 2 ] = v1.z
                custom_attribute[:array][offset_custom + 3 ] = v1.w

                custom_attribute[:array][offset_custom + 4 ] = v2.x
                custom_attribute[:array][offset_custom + 5 ] = v2.y
                custom_attribute[:array][offset_custom + 6 ] = v2.z
                custom_attribute[:array][offset_custom + 7 ] = v2.w

                custom_attribute[:array][offset_custom + 8 ] = v3.x
                custom_attribute[:array][offset_custom + 9 ] = v3.y
                custom_attribute[:array][offset_custom + 10] = v3.z
                custom_attribute[:array][offset_custom + 11] = v3.w

                offset_custom += 12
              end
            elsif custom_attribute[:bound_to] == :faces
              @faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value
                v2 = value
                v3 = value

                custom_attribute[:array][offset_custom]      = v1.x
                custom_attribute[:array][offset_custom + 1 ] = v1.y
                custom_attribute[:array][offset_custom + 2 ] = v1.z
                custom_attribute[:array][offset_custom + 3 ] = v1.w

                custom_attribute[:array][offset_custom + 4 ] = v2.x
                custom_attribute[:array][offset_custom + 5 ] = v2.y
                custom_attribute[:array][offset_custom + 6 ] = v2.z
                custom_attribute[:array][offset_custom + 7 ] = v2.w

                custom_attribute[:array][offset_custom + 8 ] = v3.x
                custom_attribute[:array][offset_custom + 9 ] = v3.y
                custom_attribute[:array][offset_custom + 10] = v3.z
                custom_attribute[:array][offset_custom + 11] = v3.w

                offset_custom += 12
              end
            elsif custom_attribute[:bound_to] == :face_vertices
              @faces3.each do |chf|
                value = custom_attribute[:value][chf]

                v1 = value[0]
                v2 = value[1]
                v3 = value[2]

                custom_attribute[:array][offset_custom]      = v1.x
                custom_attribute[:array][offset_custom + 1 ] = v1.y
                custom_attribute[:array][offset_custom + 2 ] = v1.z
                custom_attribute[:array][offset_custom + 3 ] = v1.w

                custom_attribute[:array][offset_custom + 4 ] = v2.x
                custom_attribute[:array][offset_custom + 5 ] = v2.y
                custom_attribute[:array][offset_custom + 6 ] = v2.z
                custom_attribute[:array][offset_custom + 7 ] = v2.w

                custom_attribute[:array][offset_custom + 8 ] = v3.x
                custom_attribute[:array][offset_custom + 9 ] = v3.y
                custom_attribute[:array][offset_custom + 10] = v3.z
                custom_attribute[:array][offset_custom + 11] = v3.w

                offset_custom += 12
              end
            end
          end

          glBindBuffer(GL_ARRAY_BUFFER, custom_attribute[:buffer])
          glBufferData_easy(GL_ARRAY_BUFFER, custom_attribute[:array], hint)
        end
      end

      if should_dispose
        self.dispose
      end
    end

    def dispose
      @initted_arrays = nil
      @color_array = nil
      @normal_array = nil
      @tangent_array = nil
      @uv_array = nil
      @uv2_array = nil
      @face_array = nil
      @vertex_array = nil
      @line_array = nil
      @skin_index_array = nil
      @skin_weight_array = nil
    end
  end
end
