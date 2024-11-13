require 'mittsu/core'
require 'mittsu/math'
require 'mittsu/extras/geometries/polyhedron_geometry'

module Mittsu
  class TetrahedronGeometry < PolyhedronGeometry
    def initialize(radius = 1.0, detail = 0)
      vertices = [
        1,  1,  1,   - 1, - 1,  1,   - 1,  1, - 1,    1, - 1, - 1
      ]

      indices = [
         2,  1,  0,    0,  3,  2,    1,  3,  0,    2,  3,  1
      ]

      super(vertices, indices, radius, detail)

      @type = 'TetrahedronGeometry'

      @parameters = {
        radius: radius,
        detail: detail
      }
    end
  end
end