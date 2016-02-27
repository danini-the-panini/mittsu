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
  end
end
