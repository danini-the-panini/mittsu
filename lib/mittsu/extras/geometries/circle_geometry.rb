require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class CircleGeometry < Geometry
    def initialize(radius = 50.0, segments = 8, theta_start = 0.0, theta_length = (Math::PI * 2.0))
      super()

      @type = 'CircleGeometry'

      @parameters = {
        radius:       radius,
        segments:     segments,
        theta_start:  theta_start,
        theta_length: theta_length
      }

      segments = [3, segments].max

      center = Vector3.new
      center_uv = Vector2.new(0.5, 0.5)

      @vertices << center
      uvs = [center_uv]

      for i in 0..segments do
        vertex = Vector3.new
        segment = theta_start + i.to_f / segments.to_f * theta_length

        vertex.x = radius * Math.cos(segment)
        vertex.y = radius * Math.sin(segment)

        @vertices << vertex
        uvs << Vector2.new((vertex.x / radius + 1.0) / 2.0, (vertex.y / radius + 1.0) / 2.0)
      end

      n = Vector3.new

      for i in 1..segments do
        @faces << Face3.new(i, i + 1, 0, [n.clone, n.clone, n.clone])
        @face_vertex_uvs[0] << [uvs[i].clone, uvs[i + 1].clone, center_uv.clone]
      end

      compute_face_normals
      @bounding_sphere = Sphere.new(Vector3.new, radius)
    end
  end
end
