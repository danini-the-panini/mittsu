require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class RingGeometry < Geometry
    def initialize(inner_radius = 0.0, outer_radius = 50.0, theta_segments = 8, phi_segments = 8, theta_start = 0.0, theta_length = (Math::PI * 2.0))
      super()

      @type = 'RingGeometry'

      @parameters = {
        inner_radius:   inner_radius,
        outer_radius:   outer_radius,
        theta_segments: theta_segments,
        phi_segments:   phi_segments,
        theta_start:    theta_start,
        theta_length:   theta_length
      }

      theta_segments = [3, theta_segments].max
      phi_segments = [1, phi_segments].max

      uvs = []
      radius = inner_radius
      radius_step = ((outer_radius - inner_radius) / phi_segments.to_f)

      for i in 0..phi_segments do # concentric circles inside ring
        for o in 0..theta_segments do # number of segments per circle
          vertex = Vector3.new
          segment = theta_start + o.to_f / theta_segments.to_f * theta_length
          vertex.x = radius * Math.cos(segment)
          vertex.y = radius * Math.sin(segment)

          @vertices << vertex
          uvs << Vector2.new((vertex.x / outer_radius + 1.0) / 2.0, (vertex.y / outer_radius + 1.0) / 2.0)
        end

        radius += radius_step
      end

      n = Vector3.new(0.0, 0.0, 1.0)

      for i in 0...phi_segments do # concentric circles inside ring
        theta_segment = i * (theta_segments + 1)

        for o in 0...theta_segments do # number of segments per circle
          segment = o + theta_segment

          v1 = segment
          v2 = segment + theta_segments + 1
          v3 = segment + theta_segments + 2

          @faces << Face3.new(v1, v2, v3, [n.clone, n.clone, n.clone])
          @face_vertex_uvs[0] << [uvs[v1].clone, uvs[v2].clone, uvs[v3].clone]

          v1 = segment
          v2 = segment + theta_segments + 2
          v3 = segment + 1

          @faces << Face3.new(v1, v2, v3, [n.clone, n.clone, n.clone])
          @face_vertex_uvs[0] << [uvs[v1].clone, uvs[v2].clone, uvs[v3].clone]
        end
      end

      compute_face_normals
      @bounding_sphere = Sphere.new(Vector3.new, radius)
    end

    def clone
      RingGeometry.new(
        @parameters[:inner_radius],
        @parameters[:outer_radius],
        @parameters[:theta_segments],
        @parameters[:phi_segments],
        @parameters[:theta_start],
        @parameters[:theta_length]
      )
    end
  end
end