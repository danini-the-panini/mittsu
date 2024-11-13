require 'mittsu/core'
require 'mittsu/math'
require 'mittsu/extras/geometries/torus_knot_buffer_geometry'

module Mittsu
  class TorusKnotGeometry < Geometry
    def initialize(radius = 100.0, tube = 40.0, radial_segments = 64, tubular_segments = 8, p_val = 2, q_val = 3)
      super()

      @type = 'TorusKnotGeometry'

      @parameters = {
        radius:           radius,
        tube:             tube,
        radial_segments:  radial_segments,
        tubular_segments: tubular_segments,
        p_val:            p_val,
        q_val:            q_val
      }

      from_buffer_geometry(TorusKnotBufferGeometry.new(radius, tube, tubular_segments, radial_segments, p_val, q_val))
      merge_vertices
    end
  end
end