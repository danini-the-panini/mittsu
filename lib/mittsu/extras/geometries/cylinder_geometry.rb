require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class CylinderGeometry < Geometry
    def initialize(radius_top = 20.0, radius_bottom = 20.0, height = 100.0, radial_segments = 8, height_segments = 1, open_ended = false, theta_start = 0.0, theta_length = (Math::PI * 2.0))
      super()

      @type = 'CylinderGeometry'

      @parameters = {
        radius_top:      radius_top,
        radius_bottom:   radius_bottom,
        height:          height,
        radial_segments: radial_segments,
        height_segments: height_segments,
        open_ended:      open_ended,
        theta_start:     theta_start,
        theta_length:    theta_length
      }

      height_half = height / 2.0

      index_rows = []
      uv_rows = []

      for y in 0..height_segments do
        index_row = []
        uv_row = []

        v = y.to_f / height_segments.to_f
        radius = v * (radius_bottom - radius_top) + radius_top

        for x in 0..radial_segments do
          u = x.to_f / radial_segments

          vertex = Vector3.new
          vertex.x = radius * Math.sin(u * theta_length + theta_start)
          vertex.y = -v * height + height_half
          vertex.z = radius * Math.cos(u * theta_length + theta_start)

          @vertices << vertex

          index_row << (vertices.length - 1)
          uv_row << Vector2.new(u, 1.0 - v)
        end

        index_rows << index_row
        uv_rows << uv_row
      end

      tan_theta = (radius_bottom - radius_top) / height

      na = nil
      nb = nil

      for x in 0...radial_segments do
        if radius_top != 0
          na = @vertices[index_rows[0][x]].clone
          nb = @vertices[index_rows[0][x + 1]].clone
        else
          na = @vertices[index_rows[1][x]].clone
          nb = @vertices[index_rows[1][x + 1]].clone
        end

        na.y = Math.sqrt(na.x * na.x + na.z * na.z) * tan_theta
        na.normalize

        nb.y = Math.sqrt(nb.x * nb.x + nb.z * nb.z) * tan_theta
        nb.normalize

        for y in 0...height_segments do
          v1 = index_rows[y][x]
          v2 = index_rows[y + 1][x]
          v3 = index_rows[y + 1][x + 1]
          v4 = index_rows[y][x + 1]

          n1 = na.clone
          n2 = na.clone
          n3 = nb.clone
          n4 = nb.clone

          uv1 = uv_rows[y][x].clone
          uv2 = uv_rows[y + 1][x].clone
          uv3 = uv_rows[y + 1][x + 1].clone
          uv4 = uv_rows[y][x + 1].clone

          @faces << Face3.new(v1, v2, v4, [n1, n2, n4])
          @face_vertex_uvs[0] << [uv1, uv2, uv4]

          @faces << Face3.new(v2, v3, v4, [n2.clone, n3, n4.clone])
          @face_vertex_uvs[0] << [uv2.clone, uv3, uv4.clone]
        end
      end

      # top cap

      if !open_ended && radius_top > 0.0
        @vertices << Vector3.new(0, height_half, 0)

        for x in 0...radial_segments do
          v1 = index_rows[0][x]
          v2 = index_rows[0][x + 1]
          v3 = @vertices.length - 1

          n1 = Vector3.new(0, 1, 0)
          n2 = Vector3.new(0, 1, 0)
          n3 = Vector3.new(0, 1, 0)

          uv1 = uv_rows[0][x].clone
          uv2 = uv_rows[0][x + 1].clone
          uv3 = Vector2.new(uv2.x, 0)

          @faces << Face3.new(v1, v2, v3, [n1, n2, n3])
          @face_vertex_uvs[0] << [uv1, uv2, uv3]
        end
      end

      # bottom cap

      if !open_ended && radius_bottom > 0.0
        @vertices << Vector3.new(0, -height_half, 0)

        for x in 0...radial_segments do
          v1 = index_rows[height_segments][x + 1]
          v2 = index_rows[height_segments][x]
          v3 = @vertices.length - 1

          n1 = Vector3.new(0, -1, 0)
          n2 = Vector3.new(0, -1, 0)
          n3 = Vector3.new(0, -1, 0)

          uv1 = uv_rows[height_segments][x].clone
          uv2 = uv_rows[height_segments][x + 1].clone
          uv3 = Vector2.new(uv2.x, 0)

          @faces << Face3.new(v1, v2, v3, [n1, n2, n3])
          @face_vertex_uvs[0] << [uv1, uv2, uv3]
        end
      end

      compute_face_normals
    end
  end
end
