require 'mittsu/core'
require 'mittsu/math'

module Mittsu
  class BoxGeometry < Geometry
    def initialize(width, height, depth, width_segments = nil, height_segments = nil, depth_segments = nil)
      super()

      @type = 'BoxGeometry'

      @parameters = {
        width: width,
        height: height,
        depth: depth,
        width_segments: width_segments,
        height_segments: height_segments,
        depth_segments: depth_segments
      }

      @width_segments = width_segments || 1
      @height_segments = height_segments || 1
      @depth_segments = depth_segments || 1

      width_half = width / 2.0
      height_half = height / 2.0
      depth_half = depth / 2.0

      build_plane(:z, :y, -1, -1, depth.to_f, height.to_f, width_half, 0) # px
      build_plane(:z, :y,   1, -1, depth.to_f, height.to_f, -width_half, 1) # nx
      build_plane(:x, :z,   1,   1, width.to_f, depth.to_f, height_half, 2) # py
      build_plane(:x, :z,   1, -1, width.to_f, depth.to_f, -height_half, 3) # ny
      build_plane(:x, :y,   1, -1, width.to_f, height.to_f, depth_half, 4) # pz
      build_plane(:x, :y, -1, -1, width.to_f, height.to_f, -depth_half, 5) # nz

      merge_vertices
    end

    private

    def build_plane(u, v, udir, vdir, width, height, depth, material_index)
      grid_x = @width_segments
      grid_y = @height_segments
      width_half = width / 2.0
      height_half = height / 2.0
      offset = @vertices.length

      if (u == :x && v == :y) || (u == :y && v == :x)
        w = :z
      elsif (u == :x && v == :z) || (u == :z && v == :x)
        w = :y
        grid_y = @depth_segments
      elsif (u == :z && v == :y) || (u == :y && v == :z)
        w = :x
        grid_x = @depth_segments
      end

      grid_x1 = grid_x + 1
      grid_y1 = grid_y + 1
      segment_width = width / grid_x
      segment_height = height / grid_y
      normal = Vector3.new

      normal[w] = depth > 0 ? 1.0 : -1.0

      grid_y1.times do |iy|
        grid_x1.times do |ix|
          vector = Vector3.new
          vector[u] = (ix * segment_width - width_half) * udir
          vector[v] = (iy * segment_height - height_half) * vdir
          vector[w] = depth

          @vertices.push(vector)
        end
      end

      grid_y.times do |iy|
        grid_x.times do |ix|
          a = ix + grid_x1 * iy
          b = ix + grid_x1 * (iy + 1)
          c = (ix + 1) + grid_x1 * (iy + 1)
          d = (ix + 1) + grid_x1 * iy

          uva = Vector2.new(ix / grid_x.to_f, 1.0 - iy / grid_y.to_f)
          uvb = Vector2.new(ix / grid_x.to_f, 1.0 - (iy + 1.0) / grid_y.to_f)
          uvc = Vector2.new((ix + 1.0) / grid_x.to_f, 1.0 - (iy + 1.0) / grid_y.to_f)
          uvd = Vector2.new((ix + 1.0) / grid_x.to_f, 1.0 - iy / grid_y.to_f)

          face = Face3.new(a + offset, b + offset, d + offset)
          face.normal.copy(normal)
          face.vertex_normals << normal.clone << normal.clone << normal.clone
          face.material_index = material_index

          faces << face
          face_vertex_uvs[0] << [uva, uvb, uvd]

          face = Face3.new(b + offset, c + offset, d + offset)
          face.normal.copy(normal)
          face.vertex_normals << normal.clone << normal.clone << normal.clone
          face.material_index = material_index

          faces << face
          face_vertex_uvs[0] << [uvb.clone, uvc, uvd.clone]
        end
      end

    end
  end
end
