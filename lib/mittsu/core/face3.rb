class Face3
  attr_accessor :a, :b, :c, :normal, :vertex_normals, :color, :vertex_colors, :vertex_tangents, :material_index

  def initialize(a, b, c, normal, color, material_index)
    @a = a
    @b = b
    @c = c
    @normal = normal.class == Mittsu::Vector3 ? normal : Mittsu::Vector3.new
    @vertex_normals = normal.class == Array ? normal : []
    @color = color.class == Mittsu::Color ? color : Mittsu::Color.new
    @vertex_colors = color.class == Array ? normal : []
    @vertex_tangents = []
    @material_index = material_index.nil? ? 0 : material_index
  end

  def clone
    face = THREE.face3.new(@a, @b, @c)
    face.normal.copy(@normal)
    face.color.copy(@color)
    face.material_index = @material_index
    face.vertex_normals = @vertex_normals.map(&:clone)
    face.vertex_colors = @vertex_colors.map(&:clone)
    face.vertex_tangents = @vertex_tangents.map(&:clone)
    face
  end

end
