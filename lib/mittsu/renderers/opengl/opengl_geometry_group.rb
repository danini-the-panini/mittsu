module Mittsu
  class OpenGLGeometryGroup
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
    attr_reader :id

    alias :initted_arrays? :initted_arrays

    def initialize material_index, num_morph_targets, num_morph_normals
      @id = (@@id ||= 1).tap { @@id += 1 }

      @faces3 = []
      @num_vertices = 0

      @material_index = material_index

      @num_morph_targets = num_morph_targets
      @num_morph_normals = num_morph_normals
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

    def to_group
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
