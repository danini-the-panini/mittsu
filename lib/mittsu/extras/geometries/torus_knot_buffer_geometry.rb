module Mittsu
  class TorusKnotBufferGeometry < BufferGeometry
    def initialize(radius = 100.0, tube = 40.0, radial_segments = 64, tubular_segments = 8, p_val = 2, q_val = 3)
      super()

      @type = 'TorusKnotBufferGeometry'

      @parameters = {
        radius:           radius,
        tube:             tube,
        radial_segments:  radial_segments,
        tubular_segments: tubular_segments,
        p_val:            p_val,
        q_val:            q_val
      }

      # buffers

      indices = []
      vertices = []
      normals = []
      uvs = []

      # helper variables

      vertex = Vector3.new
      normal = Vector3.new

      p1 = Vector3.new
      p2 = Vector3.new

      b = Vector3.new
      t = Vector3.new
      n = Vector3.new

      # generate vertices, normals and uvs

      for i in 0..tubular_segments do
        # the radian "u" is used to calculate the position on the torus curve of the current tubular segement
        u = i.to_f / tubular_segments.to_f * p_val.to_f * ::Math::PI * 2.0

        # now we calculate two points. P1 is our current position on the curve, P2 is a little farther ahead.
        # these points are used to create a special "coordinate space", which is necessary to calculate the correct vertex positions
        calculate_position_on_curve(u,        p_val, q_val, radius, p1)
        calculate_position_on_curve(u + 0.01, p_val, q_val, radius, p2)

        # calculate orthonormal basis
        t.sub_vectors(p2, p1)
        n.add_vectors(p2, p1)
        b.cross_vectors(t, n)
        n.cross_vectors(b, t)

        # normalize B, N. T can be ignored, we don't use it
        b.normalize
        n.normalize

        for j in 0..radial_segments do
          # now calculate the vertices. they are nothing more than an extrusion of the torus curve.
          # because we extrude a shape in the xy-plane, there is no need to calculate a z-value.
          v = j.to_f / radial_segments.to_f * ::Math::PI * 2.0
          cx = -tube * ::Math.cos(v)
          cy = tube * ::Math.sin(v)

          # now calculate the final vertex position.
          # first we orient the extrusion with our basis vectos, then we add it to the current position on the curve
          vertex.x = p1.x + (cx * n.x + cy * b.x)
          vertex.y = p1.y + (cx * n.y + cy * b.y)
          vertex.z = p1.z + (cx * n.z + cy * b.z)

          vertices += vertex.elements

          # normal (P1 is always the center/origin of the extrusion, thus we can use it to calculate the normal)
          normal.sub_vectors(vertex, p1).normalize
          
          normals += normal.elements

          # uv
          uvs << i.to_f / tubular_segments.to_f
          uvs << j.to_f / radial_segments.to_f
        end
      end

      # generate indices

      for j in 1..tubular_segments do
        for i in 1..radial_segments do
          # indices
          a = (radial_segments + 1) * (j - 1) + (i - 1)
          b = (radial_segments + 1) * j + (i - 1)
          c = (radial_segments + 1) * j + i
          d = (radial_segments + 1) * (j - 1) + i

          # faces
          indices += [a, b, d]
          indices += [b, c, d]
        end
      end

      # build geometry

      self[:index]    = BufferAttribute.new(indices, 1)
      self[:position] = BufferAttribute.new(vertices, 3)
      self[:normal]   = BufferAttribute.new(normals, 3)
      self[:uv]       = BufferAttribute.new(uvs, 2)
    end

    private

    def calculate_position_on_curve(u, p_val, q_val, radius, position)
      cu = ::Math.cos(u)
      su = ::Math.sin(u)
      qu_over_p = q_val.to_f / p_val.to_f * u
      cs = ::Math.cos(qu_over_p)

      position.x = radius * (2.0 + cs) * 0.5 * cu
      position.y = radius * (2.0 + cs) * su * 0.5
      position.z = radius * ::Math.sin(qu_over_p) * 0.5
    end
  end
end
