require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class SphereGeometry < Geometry
    def initialize(radius = 50.0, width_segments = 8, height_segments = 6, phi_start = 0.0, phi_length = (Math::PI * 2.0), theta_start = 0.0, theta_length = Math::PI)
      super()

      @type = 'SphereGeometry'

      @parameters = {
        radius: radius,
        width_segments: width_segments,
        height_segments: height_segments,
        phi_start: phi_start,
        phi_length: phi_length,
        theta_start: theta_start,
        theta_length: theta_length
      }

      width_segments = [3, width_segments.floor].max
      height_segments = [2, height_segments].max

      _vertices = []
      uvs = []

      (height_segments + 1).times do |y|
        vertices_row = []
        uvs_row = []

        (width_segments + 1).times do |x|
          u = x / width_segments.to_f
          v = y / height_segments.to_f

          vertex = Vector3.new
          vertex.x = -radius * Math.cos(phi_start + u * phi_length) * Math.sin(theta_start + v * theta_length)
          vertex.y = radius * Math.cos(theta_start + v * theta_length)
          vertex.z = radius * Math.sin(phi_start + u * phi_length) * Math.sin(theta_start + v * theta_length)

          @vertices << vertex

          vertices_row << @vertices.length - 1.0
          uvs_row << Vector2.new(u, 1.0 - v)
        end

        _vertices << vertices_row
        uvs << uvs_row
      end

      height_segments.times do |y|
        width_segments.times do |x|
          v1 = _vertices[y][x + 1]
          v2 = _vertices[y][x]
          v3 = _vertices[y + 1][x]
          v4 = _vertices[y + 1][x + 1]

          n1 = @vertices[v1].clone.normalize
          n2 = @vertices[v2].clone.normalize
          n3 = @vertices[v3].clone.normalize
          n4 = @vertices[v4].clone.normalize

          uv1 = uvs[y][x + 1].clone
          uv2 = uvs[y][x].clone
          uv3 = uvs[y + 1][x].clone
          uv4 = uvs[y + 1][x + 1].clone

          if @vertices[v1].y.abs == radius
            uv1.x = (uv1.x + uv2.x) / 2.0
            @faces << Face3.new(v1, v3, v4, [n1, n3, n4])
            @face_vertex_uvs[0] << [uv1, uv3, uv4]
          elsif @vertices[v3].y == radius
            uv3.x = (uv3.x + uv4.x) / 2.0
            @faces << Face3.new(v1, v2, v3, [n1, n2, n3])
            @face_vertex_uvs[0] << [uv1, uv2, uv3]
          else
            @faces << Face3.new(v1, v2, v4, [n1, n2, n4])
            @face_vertex_uvs[0] << [uv1, uv2, uv4]
            @faces << Face3.new(v2, v3, v4, [n2.clone, n3, n4.clone])
            @face_vertex_uvs[0] << [uv2.clone, uv3, uv4.clone]
          end
        end
      end

      compute_face_normals
      @bounding_sphere = Sphere.new(Vector3.new, radius)
    end
  end
end
