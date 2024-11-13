# parameters = {
#  color: <hex>,
#  opacity: <float>,
#  map: new THREE.Texture( <Image> ),
#
#  size: <float>,
#  sizeAttenuation: <bool>,
#
#  blending: THREE.NormalBlending,
#  depthTest: <bool>,
#  depthWrite: <bool>,
#
#  vertexColors: <bool>,
#
#  fog: <bool>
# }

module Mittsu
  class PointCloudMaterial < Material
    attr_accessor :size, :size_attenuation

    def initialize(parameters = {})
      super()

      @type = 'PointCloudMaterial'

      @color = Color.new(0xffffff)

      @map = nil

      @size = 1.0
      @size_attenuation = true

      @vertex_colors = NoColors

      @fog = true

      self.set_values(parameters)
    end

    def clone
      material = PointCloudMaterial.new
      super(material)
      material.color.copy(@color)
      material.map = @map
      material.size = @size
      material.size_attenuation = @size_attenuation
      material.vertex_colors = @vertex_colors
      material.fog = @fog
      material
    end
  end
end
