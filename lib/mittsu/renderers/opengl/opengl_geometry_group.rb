require 'mittsu/renderers/opengl/opengl_geometry_like'

module Mittsu
  class OpenGLGeometryGroup
    include OpenGLGeometryLike

    attr_reader :id

    alias :initted_arrays? :initted_arrays

    def initialize material_index, num_morph_targets, num_morph_normals, renderer
      @id = (@@id ||= 1).tap { @@id += 1 }

      @faces3 = []
      @num_vertices = 0

      @material_index = material_index

      @num_morph_targets = num_morph_targets
      @num_morph_normals = num_morph_normals

      @renderer = renderer
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
      object_impl = object.implementation(@renderer)

      nvertices = @faces3.length * 3
      nvertices2 = nvertices * 2
      nvertices3 = nvertices * 3
      nvertices4 = nvertices * 4
      ntris = @faces3.length * 1
      nlines = @faces3.length * 3

      material = object_impl.buffer_material(self)

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

    def implementation(_)
      self
    end

    private

    def glCreateBuffer
      @_b ||= ' '*8
      glGenBuffers(1, @_b)
      @_b.unpack('L')[0]
    end

    def glCreateVertexArray
      @_b ||= ' '*8
      glGenVertexArrays(1, @_b)
      @_b.unpack('L')[0]
    end
  end
end
