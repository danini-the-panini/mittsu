require 'mittsu/core'
require 'mittsu/math'
require 'mittsu/extras/geometries/polyhedron_geometry'

module Mittsu
  class OctahedronGeometry < PolyhedronGeometry
    def initialize(radius = 1.0, detail = 0)
      vertices = [
        1, 0, 0,   - 1, 0, 0,    0, 1, 0,    0,- 1, 0,    0, 0, 1,    0, 0,- 1
      ]

      indices = [
        0, 2, 4,    0, 4, 3,    0, 3, 5,    0, 5, 2,    1, 2, 5,    1, 5, 3,    1, 3, 4,    1, 4, 2
      ]

      super(vertices, indices, radius, detail)

      @type = 'OctahedronGeometry'

      @parameters = {
        radius: radius,
        detail: detail
      }
    end
  end
end