require 'mittsu/math'
require 'mittsu/materials/material'

# @author alteredq / http://alteredqualia.com/
#
# parameters = {
#  color: <hex>,
#  opacity: <float>,
#  map: new THREE.Texture( <Image> ),
#
#  blending: THREE.NormalBlending,
#  depthTest: <bool>,
#  depthWrite: <bool>,
#
#	uvOffset: new THREE.Vector2(),
#	uvScale: new THREE.Vector2(),
#
#  fog: <bool>
# }
module Mittsu
  class SpriteMaterial < Material
    attr_accessor :map, :rotation, :fog

    def initialize(parameters = {})
      super()

      @type = 'SpriteMaterial'

      @color = Color.new(0xffffff)
      @map = nil

      @rotation = 0.0

      @fog = false

      set_values(parameters)
    end

    def clone
      material = SpriteMaterial.new
      super(material)

      material.color.copy(@color)
      material.map = @map

      material.rotation = @rotation

      material.fog = @fog

      material
    end
  end
end
