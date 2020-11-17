require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class TorusGeometry < Geometry
    def initialize(radius = 100.0, tube = 40.0, radial_segments = 8, tubular_segments = 6, arc = (::Math::PI * 2.0))
      super()

      @type = 'TorusGeometry'

      @parameters = {
        radius:           radius,
        tube:             tube,
        radial_segments:  radial_segments,
        tubular_segments: tubular_segments,
        arc:              arc
      }

      center = Vector3.new
      uvs = []
      normals = []

      for j in 0..radial_segments do
        for i in 0..tubular_segments do
          u = i.to_f / tubular_segments * arc
          v = j.to_f / radial_segments * ::Math::PI * 2.0

          center.x = radius * ::Math.cos(u)
          center.y = radius * ::Math.sin(u)

          vertex = Vector3.new
          vertex.x = (radius + tube * ::Math.cos(v)) * ::Math.cos(u)
          vertex.y = (radius + tube * ::Math.cos(v)) * ::Math.sin(u)
          vertex.z = tube * ::Math.sin(v)

          @vertices << vertex

          uvs << Vector2.new(i.to_f / tubular_segments, j.to_f / radial_segments)
          normals << vertex.clone.sub(center).normalize
        end
      end

      for j in 1..radial_segments do
        for i in 1..tubular_segments do
          a = (tubular_segments + 1) * j + i - 1
          b = (tubular_segments + 1) * (j - 1) + i - 1
          c = (tubular_segments + 1) * (j - 1) + i
          d = (tubular_segments + 1) * j + i

          face = Face3.new(a, b, d, [normals[a].clone, normals[b].clone, normals[d].clone])
          @faces << face
          @face_vertex_uvs[0] << [uvs[a].clone, uvs[b].clone, uvs[d].clone]

          face = Face3.new(b, c, d, [normals[b].clone, normals[c].clone, normals[d].clone])
          @faces << face
          @face_vertex_uvs[0] << [uvs[b].clone, uvs[c].clone, uvs[d].clone]
        end
      end

      compute_face_normals
    end
  end
end
