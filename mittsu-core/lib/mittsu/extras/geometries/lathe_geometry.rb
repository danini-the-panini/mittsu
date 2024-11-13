require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class LatheGeometry < Geometry
    def initialize(points, segments = 12, phi_start = 0.0, phi_length = (::Math::PI * 2.0))
      super()

      @type = 'LatheGeometry'

      @parameters = {
        points:     points,
        segments:   segments,
        phi_start:  phi_start,
        phi_length: phi_length
      }

      inverse_point_length = 1.0 / (points.length.to_f - 1.0)
      inverse_segments = 1.0 / segments.to_f

      for i in 0..segments do
        phi = phi_start + i.to_f * inverse_segments * phi_length

        c = ::Math.cos(phi)
        s = ::Math.sin(phi)

        for j in 0...points.length do
          pt = points[j]

          vertex = Vector3.new

          vertex.x = c * pt.x
          vertex.y = pt.y
          vertex.z = s * pt.x

          @vertices << vertex
        end
      end

      np = points.length

      for i in 0...segments do
        for j in 0...(points.length - 1) do
          base = j + np * i
          a = base
          b = base + np
          c = base + 1 + np
          d = base + 1

          u0 = i.to_f * inverse_segments
          v0 = j.to_f * inverse_point_length
          u1 = u0 + inverse_segments
          v1 = v0 + inverse_point_length

          @faces << Face3.new(a, b, d)

          @face_vertex_uvs[0] << [
            Vector2.new(u0, v0),
            Vector2.new(u1, v0),
            Vector2.new(u0, v1)
          ]

          @faces << Face3.new(b, c, d)

          @face_vertex_uvs[0] << [
            Vector2.new(u1, v0),
            Vector2.new(u1, v1),
            Vector2.new(u0, v1)
          ]
        end
      end

      merge_vertices
      compute_face_normals
      compute_vertex_normals
    end
  end
end
