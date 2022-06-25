require 'mittsu/math/vector'

module Mittsu
  class Vector3 < Vector
    ELEMENTS = { x: 0, y: 1, z: 2 }
    DIMENSIONS = ELEMENTS.count

    def initialize(x = 0, y = 0, z = 0)
      super [x.to_f, y.to_f, z.to_f]
    end

    def set(x, y, z)
      super [x.to_f, y.to_f, z.to_f]
    end

    def x; @elements[0]; end
    def y; @elements[1]; end
    def z; @elements[2]; end

    def x=(value); @elements[0] = value.to_f; end
    def y=(value); @elements[1] = value.to_f; end
    def z=(value); @elements[2] = value.to_f; end

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
      _x, _y, _z = *@elements

      e = m.elements

      @elements[0] = e[0] * _x + e[3] * _y + e[6] * _z
      @elements[1] = e[1] * _x + e[4] * _y + e[7] * _z
      @elements[2] = e[2] * _x + e[5] * _y + e[8] * _z

      self
    end

    def apply_matrix4(m)
      # input: THREE.Matrix4 affine matrix
      _x, _y, _z = *@elements

      e = m.elements

      @elements[0] = e[0] * _x + e[4] * _y + e[8]  * _z + e[12]
      @elements[1] = e[1] * _x + e[5] * _y + e[9]  * _z + e[13]
      @elements[2] = e[2] * _x + e[6] * _y + e[10] * _z + e[14]

      self
    end

    def apply_projection(m)
      # input: THREE.Matrix4 projection matrix
      _x, _y, _z = *@elements

      e = m.elements
      d = 1.0 / (e[3] * _x + e[7] * _y + e[11] * _z + e[15]) # perspective divide

      @elements[0] = (e[0] * _x + e[4] * _y + e[8]  * _z + e[12]) * d
      @elements[1] = (e[1] * _x + e[5] * _y + e[9]  * _z + e[13]) * d
      @elements[2] = (e[2] * _x + e[6] * _y + e[10] * _z + e[14]) * d

      self
    end

    def apply_quaternion(q)
      _x, _y, _z = *@elements

      qx = q.x
      qy = q.y
      qz = q.z
      qw = q.w

      # calculate quat * vector
      ix =  qw * _x + qy * _z - qz * _y
      iy =  qw * _y + qz * _x - qx * _z
      iz =  qw * _z + qx * _y - qy * _x
      iw = -qx * _x - qy * _y - qz * _z

      # calculate result * inverse quat
      @elements[0] = ix * qw + iw * - qx + iy * - qz - iz * - qy
      @elements[1] = iy * qw + iw * - qy + iz * - qx - ix * - qz
      @elements[2] = iz * qw + iw * - qz + ix * - qy - iy * - qx

      self
    end

    def project(camera)
      matrix = Mittsu::Matrix4.new
      matrix.multiply_matrices(camera.projection_matrix, matrix.get_inverse(camera.matrix_world))
      self.apply_projection(matrix)
    end

    def unproject(camera)
      matrix = Mittsu::Matrix4.new
      matrix.multiply_matrices(camera.matrix_world, matrix.inverse(camera.projection_matrix))
      self.apply_projection(matrix)
    end

    def transform_direction(m)
      # input: THREE.Matrix4 affine matrix
      # vector interpreted as a direction
      _x, _y, _z = *@elements

      e = m.elements

      @elements[0] = e[0] * _x + e[4] * _y + e[8]  * _z
      @elements[1] = e[1] * _x + e[5] * _y + e[9]  * _z
      @elements[2] = e[2] * _x + e[6] * _y + e[10] * _z

      self.normalize

      self
    end

    def dot(v)
      x * v.x + y * v.y + z * v.z
    end

    def length_manhattan
      x.abs + y.abs + z.abs
    end

    def cross(v)
      _x, _y, _z = *@elements
      @elements[0] = _y * v.z - _z * v.y
      @elements[1] = _z * v.x - _x * v.z
      @elements[2] = _x * v.y - _y * v.x
      self
    end

    def cross_vectors(a, b)
      ax, ay, az = a.x, a.y, a.z
      bx, by, bz = b.x, b.y, b.z

      @elements[0] = ay * bz - az * by
      @elements[1] = az * bx - ax * bz
      @elements[2] = ax * by - ay * bx

      self
    end

    def distance_to_squared(v)
      dx = x - v.x
      dy = y - v.y
      dz = z - v.z
      dx * dx + dy * dy + dz * dz
    end

    def set_from_matrix_position(m)
      @elements[0] = m.elements[12]
      @elements[1] = m.elements[13]
      @elements[2] = m.elements[14]
      self
    end

    def set_from_matrix_scale(m)
      sx = self.set(m.elements[0], m.elements[1], m.elements[ 2]).length
      sy = self.set(m.elements[4], m.elements[5], m.elements[ 6]).length
      sz = self.set(m.elements[8], m.elements[9], m.elements[10]).length

      @elements[0] = sx
      @elements[1] = sy
      @elements[2] = sz

      self
    end

    def set_from_matrix_column(index, matrix)
      offset = index * 4

      me = matrix.elements

      @elements[0] = me[offset]
      @elements[1] = me[offset + 1]
      @elements[2] = me[offset + 2]

      self
    end

    def set_scalar(scalar)
      _x, _y, _z = *@elements

      _x = scalar
      _y = scalar
      _z = scalar

      self
    end

    def set_component(index, value)
      _x, _y, _z = *@elements

      case index
      when 0
        _x = value
        break
      when 1
        _y = value
        break
      when 2
        _z = value
        break
      else
        raise ArgumentError, "index is out of range: #{index}"
      end

      self
    end

    def get_component(index)
      _x, _y, _z = *@elements

      case index
      when 0
        return _x
      when 1
        return _y
      when 2
        return _z
      else
        raise ArgumentError, "index is out of range: #{index}"
      end
    end

    def add_scaled_vector(vector, scalar)
      _x, _y, _z = *@elements

      _x = vector.x * scalar
      _y = vector.y * scalar
      _z = vector.z * scalar

      self
    end

    def set_from_spherical(sphere)
      set_from_spherical_coords(sphere.radius, sphere.phi, sphere.theta)
    end

    def set_from_spherical_coords(radius, phi, theta)
      _x, _y, _z = *@elements

      sin_phi_radius = Math.sin(phi) * radius
      _x = sin_phi_radius * Math.sin(theta)
      _y = Math.cos(phi) * radius
      _z = sin_phi_radius * Math.cos(theta)

      self
    end

    def set_from_cylindrical(cylinder)
      set_from_cylindrical_coords(cylinder.radius, cylinder.theta, cylinder.y)
    end

    def set_from_cylindrical_coords(radius, theta, y)
      _x, _y, _z = *@elements

      _x = radius * Math.sin(theta)
      _y = y
      _z = radius * Math.cos(theta)

      self
    end

    def set_from_matrix_3_column(matrix, index)
      from_array(matrix.elements, index * 3)
    end

    def equals(vector)
      _x, _y, _z = *@elements

      ((vector.x == _x) && (vector.y == _y) && (vector.z == _z ))
    end

    def from_buffer_attribute(attribute, index)
      _x, _y, _z = *@elements

      _x = attribute.get_x(index);
      _y = attribute.get_y(index);
      _z = attribute.get_z(index);

      self
    end

    def clamp_length(min, max)
      divide_scalar(length || 1).multiply_scalar(Math.max(min, Math.min(max, length)))
    end

    def manhattan_distance_to(vector)
      _x, _y, _z = *@elements

      (_x - vector.x).abs + (_y - vector.y).abs + (_z - vector.z).abs
    end

    def random
      _x, _y, _z = *@elements

      _x = Math.random
      _y = Math.random
      _z = Math.random

      self
    end

    def random_direction()
      _x, _y, _z = *@elements

      u = (Math.random() - 0.5) *2
      t = Math.random() * Math::PI * 2
      f = (1 - u ** 2).sqrt

      _x = f * Math.cos(t)
      _y = f * Math.sin(t)
      _z = u

      self
    end

    def from_attribute(attribute, index, offset = 0)
      index = index * attribute.itemSize + offset

      @elements[0] = attribute.array[index]
      @elements[1] = attribute.array[index + 1]
      @elements[2] = attribute.array[index + 2]

      self
    end
  end
end
