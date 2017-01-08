module Mittsu
  class Sprite < Object3D
    attr_accessor :material, :z

    INDICES = [0, 1, 2,
               0, 2, 3] # Uint16Array
    VERTICES = [-0.5, -0.5, 0.0,
                0.5, -0.5, 0.0,
                0.5, 0.5, 0.0,
                -0.5, 0.5, 0.0] # Float32Array
    UVS = [0.0, 0.0,
           1.0, 0.0,
           1.0, 1.0,
           0.0, 1.0] # Float32Array

    GEOMETRY = BufferGeometry.new
    GEOMETRY[:index] = BufferAttribute.new(INDICES, 1)
    GEOMETRY[:position] = BufferAttribute.new(VERTICES, 3)
    GEOMETRY[:uv] = BufferAttribute.new(UVS, 2)

    def initialize(material = SpriteMaterial.new)
      super()

      @type = 'Sprite'

      @geometry = GEOMETRY
      @material = material
      @z = nil
    end

    def raycast(raycaster, intersects)
      @_matrix_position ||= Vector3.new

      @_matrix_position.set_from_matrix_position(@matrix_world)

      distance = raycaster.ray.distance_to_pint(@_matrix_position)

      return if distance > @scale.x

      intersects.push({
        distance: distance,
        point: @position,
        face: nil,
        object: self
        })
    end

    def clone(object = Sprite.new(@material))
      super(object)
      object
    end
  end
end
