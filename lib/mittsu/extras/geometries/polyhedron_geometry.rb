require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class PolyhedronGeometry < Geometry
    def initialize(vertices, indices, radius = 1.0, detail = 0)
      super()

      @type = 'PolyhedronGeometry'

      @parameters = {
        vertices: vertices,
        indices:  indices,
        radius:   radius,
        detail:   detail
      }

      for i in (0...vertices.length).step(3) do
        prepare(Vector3.new(vertices[i], vertices[i + 1], vertices[i + 2]))
      end

      faces = []

      i = 0
      j = 0
      while i < indices.length do
        v1 = @vertices[indices[i]]
        v2 = @vertices[indices[i + 1]]
        v3 = @vertices[indices[i + 2]]
        binding.irb if v1.nil? || v2.nil? || v3.nil?

        faces[j] = Face3.new(v1.index, v2.index, v3.index, [v1.clone, v2.clone, v3.clone])

        i += 3
        j += 1
      end

      @centroid = Vector3.new

      for i in 0...faces.length do
        subdivide(faces[i], detail)
      end

      # Handle case when face straddles the seam

      @face_vertex_uvs[0].each do |uv0, uv1, uv2|
        x0 = uv0.x
        x1 = uv1.x
        x2 = uv2.x

        max = [x0, x1, x2].max
        min = [x0, x1, x2].min

        if max > 0.9 && min < 0.1 # 0.9 is somewhat arbitrary
          uv0.x += 1.0 if x0 < 0.2
          uv1.x += 1.0 if x1 < 0.2
          uv2.x += 1.0 if x2 < 0.2
        end
      end

      # Apply radius

      @vertices.each do |v|
        v.multiply_scalar(radius)
      end

      merge_vertices

      compute_face_normals
      @bounding_sphere = Sphere.new(Vector3.new, radius)
    end

    private

    # Project vector onto sphere's surface
    def prepare(vector)
      vertex = vector.normalize.clone
      vertex.index = @vertices.push(vertex).length - 1

      # Texture coords are equivalent to map coords, calculate angle and convert to fraction of a circle.
      u = azimuth(vector) / 2.0 / ::Math::PI + 0.5
      v = inclination(vector) / ::Math::PI + 0.5
      vertex.uv = Vector2.new(u, 1.0 - v)

      vertex
    end

    # Approximate a curved face with recursively sub-divided triangles.
    def make(v1, v2, v3)
      face = Face3.new(v1.index, v2.index, v3.index, [v1.clone, v2.clone, v3.clone])
      @faces << face

      @centroid.copy(v1).add(v2).add(v3).divide_scalar(3)

      azi = azimuth(@centroid)

      @face_vertex_uvs[0] << [
        correct_uv(v1.uv, v1, azi),
        correct_uv(v2.uv, v2, azi),
        correct_uv(v3.uv, v3, azi)
      ]
    end

    # Analytically subdivide a face to the required detail level.
    def subdivide(face, detail)
      cols = 2.0 ** detail
      a = prepare(@vertices[face.a])
      b = prepare(@vertices[face.b])
      c = prepare(@vertices[face.c])
      v = []

      # Construct all of the vertices for this subdivision.
      for i in 0..cols do
        v[i] = []

        aj = prepare(a.clone.lerp(c, i.to_f / cols.to_f))
        bj = prepare(b.clone.lerp(c, i.to_f / cols.to_f))
        rows = cols - i

        for j in 0..rows do
          v[i][j] = if j.zero? && i == cols
                      aj
                    else
                      prepare(aj.clone.lerp(bj, j.to_f / rows.to_f))
                    end
        end
      end

      # Construct all of the faces
      for i in 0...cols do
        for j in (0...(2 * (cols - i) - 1)) do
          k = j/2

          if j.even?
            make(
              v[i][k + 1],
              v[i + 1][k],
              v[i][k]
            )
          else
            make(
              v[i][k + 1],
              v[i + 1][k + 1],
              v[i + 1][k]
            )
          end
        end
      end
    end

    # Angle around the Y axis, counter-clockwise when looking from above.
    def azimuth(vector)
      ::Math.atan2(vector.z, -vector.x)
    end

    # Angle above the XZ plane.
    def inclination(vector)
      ::Math.atan2(-vector.y, ::Math.sqrt(vector.x * vector.x + vector.z * vector.z))
    end

    # Texture fixing helper. Spheres have some odd behaviours.
    def correct_uv(uv, vector, azimuth)
      return Vector2.new(uv.x - 1.0, uv.y) if azimuth < 0
      return Vector2.new(azimuth / 2.0 / ::Math::PI + 0.5, uv.y) if vector.x.zero? && vector.z.zero?
      uv.clone
    end
  end
end
