require 'mittsu/math'

module Mittsu
  class Face3
    attr_accessor :a, :b, :c, :normal, :vertex_normals, :color, :vertex_colors, :vertex_tangents, :material_index

    def initialize(a, b, c, normal = nil, color = nil, material_index = nil)
      @a = a
      @b = b
      @c = c
      @normal = normal.is_a?(Vector3) ? normal : Mittsu::Vector3.new
      @vertex_normals = normal.is_a?(Array) ? normal : []
      @color = color.is_a?(Color) ? color : Mittsu::Color.new
      @vertex_colors = color.is_a?(Array) ? normal : []
      @vertex_tangents = []
      @material_index = material_index.nil? ? 0 : material_index
    end

    def clone
      face = Mittsu::Face3.new(@a, @b, @c)
      face.normal.copy(@normal)
      face.color.copy(@color)
      face.material_index = @material_index
      face.vertex_normals = @vertex_normals.map(&:clone)
      face.vertex_colors = @vertex_colors.map(&:clone)
      face.vertex_tangents = @vertex_tangents.map(&:clone)
      face
    end
  end
end
