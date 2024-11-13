module Mittsu
  class ParametricBufferGeometry < BufferGeometry
    EPS = 0.00001

    def initialize(func, slices, stacks)
      super()

      @type = 'ParametricBufferGeometry'

      @parameters = {
        func:   func,
        slices: slices,
        stacks: stacks
      }

      # buffers

      indices = []
      vertices = []
      normals = []
      uvs = []

      normal = Vector3.new

      p0 = Vector3.new
      p1 = Vector3.new

      pu = Vector3.new
      pv = Vector3.new

      # generate vertices, normals, and uvs

      slice_count = slices + 1

      for i in 0..stacks do
        v = i.to_f / stacks.to_f

        for j in 0..slices do
          u = j.to_f / slices.to_f

          # vertex
          func.call(u, v, p0)
          vertices += p0.elements

          # normal

          # approximate tangent vectors via finite differences
          if u - EPS >= 0
            func.call(u - EPS, v, p1)
            pu.sub_vectors(p0, p1)
          else
            func.call(u + EPS, v, p1)
            pu.sub_vectors(p1, p0)
          end

          if v - EPS >= 0
            func.call(u, v - EPS, p1)
            pv.sub_vectors(p0, p1)
          else
            func.call(u, v + EPS, p1)
            pv.sub_vectors(p1, p0)
          end

          # cross product of tangent vectors returns surface normal
          normal.cross_vectors(pu, pv).normalize
          normals += normal.elements

          # uv
          uvs << u << v
        end
      end

      for i in 0...stacks do
        for j in 0...slices do
          a = i * slice_count + j
          b = i * slice_count + j + 1
          c = (i + 1) * slice_count + j + 1
          d = (i + 1) * slice_count + j

          # faces one and two
          indices << a << b << d
          indices << b << c << d
        end
      end

      self[:index]    = BufferAttribute.new(indices, 1)
      self[:position] = BufferAttribute.new(vertices, 3)
      self[:normal]   = BufferAttribute.new(normals, 3)
      self[:uv]       = BufferAttribute.new(uvs, 2)
    end
  end
end