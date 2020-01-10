module Mittsu
  class PlaneBufferGeometry < BufferGeometry
    def initialize(width, height, width_segments = 1, height_segments = 1)
      super()

      @type = 'PlaneBufferGeometry'

      @parameters = {
        width:           width,
        height:          height,
        width_segments:  width_segments,
        height_segments: height_segments
      }

      width_half = width / 2.0
      height_half = height / 2.0

      grid_x = width_segments || 1
      grid_y = height_segments || 1

      grid_x1 = grid_x + 1
      grid_y1 = grid_y + 1

      segment_width = width.to_f / grid_x.to_f
      segment_height = height.to_f / grid_y.to_f

      vertices = Array.new(grid_x1 * grid_y1 * 3) # Float32Array
      normals = Array.new(grid_x1 * grid_y1 * 3) #Float32Array
      uvs = Array.new(grid_x1 * grid_y1 * 2) # Float32Array

      offset = 0
      offset2 = 0

      for iy in 0...grid_y1 do
        y = iy.to_f * segment_height - height_half
        for ix in 0...grid_x1 do
          x = ix.to_f * segment_width - width_half

          vertices[offset] = x
          vertices[offset + 1] = -y

          normals[offset + 2] = 1.0

          uvs[offset2] = ix.to_f / grid_x.to_f
          uvs[offset2 + 1] = 1.0 - (iy.to_f / grid_y.to_f)

          offset += 3
          offset2 += 2
        end
      end

      offset = 0

      indices = Array.new(grid_x * grid_y * 6) # ( ( vertices.length / 3 ) > 65535 ? Uint32Array : Uint16Array )

      for iy in 0...grid_y do
        for ix in 0...grid_x do
          a = ix + grid_x1 * iy
          b = ix + grid_x1 * (iy + 1)
          c = (ix + 1) + grid_x1 * (iy + 1)
          d = (ix + 1) + grid_x1 * iy

          indices[offset    ] = a
          indices[offset + 1] = b
          indices[offset + 2] = d

          indices[offset + 3] = b
          indices[offset + 4] = c
          indices[offset + 5] = d

          offset += 6
        end
      end

      self[:index]    = BufferAttribute.new(indices, 1)
      self[:position] = BufferAttribute.new(vertices, 3)
      self[:normal]   = BufferAttribute.new(normals, 3)
      self[:uv]       = BufferAttribute.new(uvs, 2)
    end
  end
end