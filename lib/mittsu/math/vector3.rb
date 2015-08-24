require 'mittsu/math'

module Mittsu
  class Vector3
    attr_reader :x, :y, :z

    def initialize(x = 0, y = 0, z = 0)
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
    end

    def x=(value)
      @x = value.to_f
    end

    def y=(value)
      @y = value.to_f
    end

    def z=(value)
      @z = value.to_f
    end

    def set(x, y, z)
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
      self
    end

    def []=(index, value)
      return @x = value.to_f if index == 0 || index == :x
      return @y = value.to_f if index == 1 || index == :y
      return @z = value.to_f if index == 2 || index == :z
      raise IndexError
    end

    def [](index)
      return @x if index == 0 || index == :x
      return @y if index == 1 || index == :y
      return @z if index == 2 || index == :z
      raise IndexError
    end

    def copy(v)
      @x = v.x
      @y = v.y
      @z = v.z
      self
    end

    def add(v)
      @x += v.x
      @y += v.y
      @z += v.z
      self
    end

    def add_scalar(s)
      @x += s
      @y += s
      @z += s
      self
    end

    def add_vectors(a, b)
      @x = a.x + b.x
      @y = a.y + b.y
      @z = a.z + b.z
      self
    end

    def sub(v)
      @x -= v.x
      @y -= v.y
      @z -= v.z
      self
    end

    def sub_scalar(s)
      @x -= s
      @y -= s
      @z -= s
      self
    end

    def sub_vectors(a, b)
      @x = a.x - b.x
      @y = a.y - b.y
      @z = a.z - b.z
      self
    end

    def multiply(v)
      @x *= v.x
      @y *= v.y
      @z *= v.z
      self
    end

    def multiply_scalar(scalar)
      @x *= scalar
      @y *= scalar
      @z *= scalar
      self
    end

    def multiply_vectors(a, b)
      @x = a.x * b.x
      @y = a.y * b.y
      @z = a.z * b.z
      self
    end

    def apply_euler(euler)
      quaternion = Mittsu::Quaternion.new
      self.apply_quaternion(quaternion.set_from_euler(euler))
      self
    end

    def apply_axis_angle(axis, angle)
      quaternion = Mittsu::Quaternion.new
      self.apply_quaternion(quaternion.set_from_axis_angle(axis, angle))
      self
    end

    def apply_matrix3(m)
      x = @x
      y = @y
      z = @z

      e = m.elements

      @x = e[0] * x + e[3] * y + e[6] * z
      @y = e[1] * x + e[4] * y + e[7] * z
      @z = e[2] * x + e[5] * y + e[8] * z

      self
    end

    def apply_matrix4(m)
      # input: THREE.Matrix4 affine matrix

      xx, yy, zz = @x, @y, @z

      e = m.elements

      @x = e[0] * xx + e[4] * yy + e[8]  * zz + e[12]
      @y = e[1] * xx + e[5] * yy + e[9]  * zz + e[13]
      @z = e[2] * xx + e[6] * yy + e[10] * zz + e[14]

      self
    end

    def apply_projection(m)
      # input: THREE.Matrix4 projection matrix

      _x, _y, _z = @x, @y, @z

      e = m.elements
      d = 1.0 / (e[3] * _x + e[7] * _y + e[11] * _z + e[15]) # perspective divide

      @x = (e[0] * _x + e[4] * _y + e[8]  * _z + e[12]) * d
      @y = (e[1] * _x + e[5] * _y + e[9]  * _z + e[13]) * d
      @z = (e[2] * _x + e[6] * _y + e[10] * _z + e[14]) * d

      self
    end

    def apply_quaternion(q)
      x = @x
      y = @y
      z = @z

      qx = q.x
      qy = q.y
      qz = q.z
      qw = q.w

      # calculate quat * vector

      ix =  qw * x + qy * z - qz * y
      iy =  qw * y + qz * x - qx * z
      iz =  qw * z + qx * y - qy * x
      iw = - qx * x - qy * y - qz * z

      # calculate result * inverse quat

      @x = ix * qw + iw * - qx + iy * - qz - iz * - qy
      @y = iy * qw + iw * - qy + iz * - qx - ix * - qz
      @z = iz * qw + iw * - qz + ix * - qy - iy * - qx

      self
    end

    def project(camera)
      matrix = Mittsu::Matrix4.new
      matrix.multiply_matrices(camera.projection_matrix, matrix.get_inverse(camera.matrix_world))
      self.apply_projection(matrix)
    end

    def unproject(camera)
      matrix = Mittsu::Matrix4.new
      matrix.multiply_matrices(camera.matrix_world, matrix.get_inverse(camera.projection_matrix))
      self.apply_projection(matrix)
    end

    def transform_direction(m)
      # input: THREE.Matrix4 affine matrix
      # vector interpreted as a direction

      x = @x, y = @y, z = @z

      e = m.elements

      @x = e[0] * x + e[4] * y + e[8]  * z
      @y = e[1] * x + e[5] * y + e[9]  * z
      @z = e[2] * x + e[6] * y + e[10] * z

      self.normalize

      self
    end

    def divide(v)
      @x /= v.x
      @y /= v.y
      @z /= v.z
      self
    end

    def divide_scalar(scalar)
      if scalar != 0
        invScalar = 1.0 / scalar
        @x *= invScalar
        @y *= invScalar
        @z *= invScalar
      else
        @x = 0
        @y = 0
        @z = 0
      end
      self
    end

    def min(v)
      if @x > v.x
        @x = v.x
      end
      if @y > v.y
        @y = v.y
      end
      if @z > v.z
        @z = v.z
      end
      self
    end

    def max(v)
      if @x < v.x
        @x = v.x
      end
      if @y < v.y
        @y = v.y
      end
      if @z < v.z
        @z = v.z
      end
      self
    end

    def clamp(min, max)
      @x = Math.clamp(@x, min.x, max.x)
      @y = Math.clamp(@y, min.y, max.y)
      @z = Math.clamp(@z, min.z, max.z)
      self
    end

    def clamp_scalar(min, max)
      @x = Math.clamp(@x, min, max)
      @y = Math.clamp(@y, min, max)
      @z = Math.clamp(@z, min, max)
      self
    end

    def floor
      @x = @x.floor.to_f
      @y = @y.floor.to_f
      @z = @z.floor.to_f
      self
    end

    def ceil
      @x = @x.ceil.to_f
      @y = @y.ceil.to_f
      @z = @z.ceil.to_f
      self
    end

    def round
      @x = @x.round.to_f
      @y = @y.round.to_f
      @z = @z.round.to_f
      self
    end

    def round_to_zero
      @x = (@x < 0) ? @x.ceil.to_f : @x.floor.to_f
      @y = (@y < 0) ? @y.ceil.to_f : @y.floor.to_f
      @z = (@z < 0) ? @z.ceil.to_f : @z.floor.to_f
      self
    end

    def negate
      @x = - @x
      @y = - @y
      @z = - @z
      self
    end

    def dot(v)
      @x * v.x + @y * v.y + @z * v.z
    end

    def length_sq
      self.dot(self)
    end

    def length
      Math.sqrt(length_sq)
    end

    def length_manhattan
      @x.abs + @y.abs + @z.abs
    end

    def normalize
      self.divide_scalar(self.length)
    end

    def set_length(l)
      old_length = self.length
      if old_length != 0 && l != old_length
        self.multiply_scalar(l / old_length)
      end
      self
    end

    def lerp(v, alpha)
      @x += (v.x - @x) * alpha
      @y += (v.y - @y) * alpha
      @z += (v.z - @z) * alpha
      self
    end

    def lerp_vectors(v1, v2, alpha)
      self.sub_vectors(v2, v1).multiply_scalar(alpha).add(v1)
      self
    end

    def cross(v)
      x, y, z = @x, @y, @z
      @x = y * v.z - z * v.y
      @y = z * v.x - x * v.z
      @z = x * v.y - y * v.x
      self
    end

    def cross_vectors(a, b)
      ax = a.x, ay = a.y, az = a.z
      bx = b.x, by = b.y, bz = b.z

      @x = ay * bz - az * by
      @y = az * bx - ax * bz
      @z = ax * by - ay * bx

      self
    end

    def project_on_vector(vector)
      v1 = Mittsu::Vector3.new
      v1.copy(vector).normalize
      dot = self.dot(v1)
      self.copy(v1).multiply_scalar(dot)
    end

    def project_on_plane(plane_normal)
      v1 = Mittsu::Vector3.new
      v1.copy(self).project_on_vector(plane_normal)
      self.sub(v1)
    end

    def reflect(normal)
      # reflect incident vector off plane orthogonal to normal
      # normal is assumed to have unit length
      v1 = Mittsu::Vector3.new
      self.sub(v1.copy(normal).multiply_scalar(2.0 * self.dot(normal)))
    end

    def angle_to(v)
      theta = self.dot(v) / (self.length * v.length)

      # clamp, to handle numerical problems
      Math.acos(Math.clamp(theta, -1.0, 1.0))
    end

    def distance_to(v)
      Math.sqrt(self.distance_to_squared(v))
    end

    def distance_to_squared(v)
      dx = @x - v.x
      dy = @y - v.y
      dz = @z - v.z
      dx * dx + dy * dy + dz * dz
    end

    def set_from_matrix_position(m)
      @x = m.elements[12]
      @y = m.elements[13]
      @z = m.elements[14]
      self
    end

    def set_from_matrix_scale(m)
      sx = self.set(m.elements[0], m.elements[1], m.elements[ 2]).length
      sy = self.set(m.elements[4], m.elements[5], m.elements[ 6]).length
      sz = self.set(m.elements[8], m.elements[9], m.elements[10]).length

      @x = sx
      @y = sy
      @z = sz

      self
    end

    def set_from_matrix_column(index, matrix)
      offset = index * 4

      me = matrix.elements

      @x = me[offset]
      @y = me[offset + 1]
      @z = me[offset + 2]

      self
    end

    def ==(v)
      ((v.x == @x) && (v.y == @y) && (v.z == @z))
    end

    def fromArray(array, offset = 0)
      @x = array[offset]
      @y = array[offset + 1]
      @z = array[offset + 2]
      self
    end

    def to_array(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array[offset + 2] = @z

      array
    end

    def to_a
      self.to_array
    end

    def from_attribute(attribute, index, offse = 0)
      index = index * attribute.itemSize + offset

      @x = attribute.array[index]
      @y = attribute.array[index + 1]
      @z = attribute.array[index + 2]

      self
    end

    def clone
      Mittsu::Vector3.new(@x, @y, @z)
    end
  end
end
