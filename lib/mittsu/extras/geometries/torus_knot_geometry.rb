require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class TorusKnotGeometry < Geometry
    def initialize(radius = 100.0, tube = 40.0, radial_segments = 64, tubular_segments = 8, p = 2, q = 3, height_scale = 1.0)
      super()

      @type = 'TorusKnotGeometry'

      @parameters = {
        radius:           radius,
        tube:             tube,
        radial_segments:  radial_segments,
        tubular_segments: tubular_segments,
        p:                p,
        q:                q,
        height_scale:     height_scale
      }

      grid = Array.new(radial_segments)
    	tang = Vector3.new
      n = Vector3.new
      bitan = Vector3.new

      for i in 0...radial_segments do
        grid[i] = Array.new(tubular_segments)
        u = i.to_f / radial_segments * 2.0 * p.to_f * Math::PI
        p1 = get_pos(u, q, p, radius, height_scale)
        p2 = get_pos(u + 0.01, q, p, radius, height_scale)
        tang.sub_vectors(p2, p1)
        n.add_vectors(p2, p1)

        bitan.cross_vectors(tang, n)
        n.cross_vectors(bitan, tang)
        bitan.normalize
        n.normalize

        for j in 0...tubular_segments
          v = j.to_f / tubular_segments * 2.0 * Math::PI
          cx = -tube * Math.cos(v) # TODO: Hack: Negating it so it faces outside.
          cy = tube * Math.sin(v)

          pos = Vector3.new
          pos.x = p1.x + cx * n.x + cy * bitan.x
          pos.y = p1.y + cx * n.y + cy * bitan.y
          pos.z = p1.z + cx * n.z + cy * bitan.z

          grid[i][j] = @vertices.push(pos).length - 1
        end
      end

      for i in 0...radial_segments do
        for j in 0...tubular_segments do
          ip = (i + 1) % radial_segments
          jp = (j + 1) % tubular_segments

          a = grid[i][j]
          b = grid[ip][j]
          c = grid[ip][jp]
          d = grid[i][jp]

          uva = Vector2.new(i.to_f         / radial_segments.to_f, j.to_f         / tubular_segments.to_f)
          uvb = Vector2.new((i.to_f + 1.0) / radial_segments.to_f, j.to_f         / tubular_segments.to_f)
          uvc = Vector2.new((i.to_f + 1.0) / radial_segments.to_f, (j.to_f + 1.0) / tubular_segments.to_f)
          uvd = Vector2.new(i.to_f         / radial_segments.to_f, (j.to_f + 1.0) / tubular_segments.to_f)

          @faces << Face3.new(a, b, d)
          @face_vertex_uvs[0] << [uva, uvb, uvd]

          @faces << Face3.new(b, c, d)
          @face_vertex_uvs[0] << [uvb.clone, uvc, uvd.clone]
        end
      end

      compute_face_normals
      compute_vertex_normals
    end

    private

    def get_pos(u, in_q, in_p, radius, height_scale)
      cu = Math.cos(u)
      su = Math.sin(u)
      qu_over_p = in_q.to_f / in_p.to_f * u
      cs = Math.cos(qu_over_p)

      tx = radius * (2.0 + cs) * 0.5 * cu
      ty = radius * (2.0 + cs) * su * 0.5
      tz = height_scale * radius * Math.sin(qu_over_p) * 0.5

      return Vector3.new(tx, ty, tz)
    end
  end
end