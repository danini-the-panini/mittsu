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
  end
end
