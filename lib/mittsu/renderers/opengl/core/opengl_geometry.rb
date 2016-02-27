require 'mittsu/renderers/opengl/opengl_geometry_like'

module Mittsu
  class OpenGLGeometry
    include OpenGLGeometryLike

    attr_accessor :groups
    attr_reader :id

    def initialize(geometry, renderer)
      @id = (@@id ||= 1).tap { @@id += 1 }

      @geometry = geometry
      @renderer = renderer
    end

    def init_geometry_groups(object)
      object_impl = object.implementation(@renderer)
      material = object.material
      add_buffers = false

      if @groups.nil? || @geometry.groups_need_update
        # TODO!!!
        @renderer.instance_variable_get(:@_opengl_objects).delete object.id

        @groups = make_groups(material.is_a?(MeshFaceMaterial))

        @geometry.groups_need_update = false
      end

      # create separate VBOs per geometry chunk

      @groups.each do |geometry_group|
        # initialize VBO on the first access
        if geometry_group.vertex_buffer.nil?
          # TODO!!!
          @renderer.send(:create_mesh_buffers, geometry_group)
          @renderer.send(:init_mesh_buffers, geometry_group, object)

          @geometry.vertices_need_update = true
          @geometry.morph_targets_need_update = true
          @geometry.elements_need_update = true
          @geometry.uvs_need_update = true
          @geometry.normals_need_update = true
          @geometry.tangents_need_update = true
          @geometry.colors_need_update = true
        else
          add_buffers = false
        end

        if add_buffers || !object_impl.active?
          # TODO!!! FIXME!!!!
          @renderer.send(:add_buffer, @renderer.instance_variable_get(:@_opengl_objects), geometry_group, object)
        end
      end

      object_impl.active = true
    end

    def init_line_buffers(object)
      nvertices = @geometry.vertices.length

      @vertex_array = Array.new(nvertices * 3, 0.0) # Float32Array
      @color_array = Array.new(nvertices * 3, 0.0) # Float32Array
      @line_distance_array = Array.new(nvertices, 0.0) # Float32Array

      @line_count = nvertices

      init_custom_attributes(object)
    end

    def create_line_buffers
      @vertex_array_object = glCreateVertexArray

      @vertex_buffer = glCreateBuffer
      @color_buffer = glCreateBuffer
      @line_distance_buffer = glCreateBuffer

      @renderer.info[:memory][:geometries] += 1
    end

    private

    def make_groups(uses_face_material = false)
      max_vertices_in_group = 65535 # TODO: OES_element_index_uint ???

      hash_map = {}

      num_morph_targets = @geometry.morph_targets.length
      num_morph_normals = @geometry.morph_normals.length

      groups = {}
      groups_list = []

      @geometry.faces.each_with_index do |face, f|
        material_index = uses_face_material ? face.material_index : 0

        if !hash_map.include? material_index
          hash_map[material_index] = { hash: material_index, counter: 0 }
        end

        group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

        if !groups.include? group_hash
          group = OpenGLGeometryGroup.new(material_index, num_morph_targets, num_morph_normals)

          groups[group_hash] = group
          groups_list << group
        end

        if groups[group_hash].num_vertices + 3 > max_vertices_in_group
          hash_map[material_index][:counter] += 1
          group_hash = "#{hash_map[material_index][:hash]}_#{hash_map[material_index][:counter]}"

          if !groups.include? group_hash
            group = OpenGLGeometryGroup.new(material_index, num_morph_targets, num_morph_normals)

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

      nvertices = @geometry.vertices.length

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

            attribute.array = Array.new(nvertices * size) # Float32Array

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
