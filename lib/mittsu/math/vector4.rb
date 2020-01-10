require 'mittsu/math/vector'

module Mittsu
  class Vector4 < Vector
    ELEMENTS = { x: 0, y: 1, z: 2, w: 3 }
    DIMENSIONS = ELEMENTS.count

    def initialize(x = 0, y = 0, z = 0, w = 1)
      super [x.to_f, y.to_f, z.to_f, w.to_f]
    end

    def set(x, y, z, w)
      super [x.to_f, y.to_f, z.to_f, w.to_f]
    end

    def x; @elements[0]; end
    def y; @elements[1]; end
    def z; @elements[2]; end
    def w; @elements[3]; end

    def x=(value); @elements[0] = value.to_f; end
    def y=(value); @elements[1] = value.to_f; end
    def z=(value); @elements[2] = value.to_f; end
    def w=(value); @elements[3] = value.to_f; end

    def apply_matrix4(m)
      _x, _y, _z, _w = *@elements
      e = m.elements
      @elements[0] = e[0] * _x + e[4] * _y + e[8]  * _z + e[12] * _w
      @elements[1] = e[1] * _x + e[5] * _y + e[9]  * _z + e[13] * _w
      @elements[2] = e[2] * _x + e[6] * _y + e[10] * _z + e[14] * _w
      @elements[3] = e[3] * _x + e[7] * _y + e[11] * _z + e[15] * _w
      self
    end

    def divide_scalar(scalar)
      if scalar != 0.0
        inv_scalar = 1.0 / scalar
        @elements[0] *= inv_scalar
        @elements[1] *= inv_scalar
        @elements[2] *= inv_scalar
        @elements[3] *= inv_scalar
      else
        @elements = [0.0, 0.0, 0.0, 1.0]
      end
      self
    end

    def set_axis_angle_from_quaternion(q)
      # http:#www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle/index.htm
      # q is assumed to be normalized
      @elements[3] = 2.0 * Math.acos(q.w)
      s = Math.sqrt(1.0 - q.w * q.w)
      if s < 0.0001
         @elements[0] = 1.0
         @elements[1] = 0.0
         @elements[2] = 0.0
      else
         @elements[0] = q.x / s
         @elements[1] = q.y / s
         @elements[2] = q.z / s
      end
      self
    end

    def set_axis_angle_from_rotation_matrix(m)
      # http:#www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
      # assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
      angle, x1, y1, z1 = nil    # variables for result
      epsilon = 0.01    # margin to allow for rounding errors
      epsilon2 = 0.1    # margin to distinguish between 0 and 180 degrees
      te = m.elements
      m11, m12, m13 = te[0], te[4], te[8]
      m21, m22, m23 = te[1], te[5], te[9]
      m31, m32, m33 = te[2], te[6], te[10]
      if (((m12 - m21).abs < epsilon) &&
          ((m13 - m31).abs < epsilon) &&
          ((m23 - m32).abs < epsilon))
        # singularity found
        # first check for identity matrix which must have +1 for all terms
        # in leading diagonal and zero in other terms
        if (((m12 + m21).abs < epsilon2) &&
            ((m13 + m31).abs < epsilon2) &&
            ((m23 + m32).abs < epsilon2) &&
            ((m11 + m22 + m33 - 3).abs < epsilon2))
          # self singularity is identity matrix so angle = 0
          @elements = [1.0, 0.0, 0.0, 0.0]
          return self # zero angle, arbitrary axis
        end
        # otherwise self singularity is angle = 180
        angle = Math::PI
        xx = (m11 + 1.0) / 2.0
        yy = (m22 + 1.0) / 2.0
        zz = (m33 + 1.0) / 2.0
        xy = (m12 + m21) / 4.0
        xz = (m13 + m31) / 4.0
        yz = (m23 + m32) / 4.0
        if (xx > yy) && (xx > zz) # m11 is the largest diagonal term
          if xx < epsilon
            x1 = 0.0
            y1 = 0.707106781
            z1 = 0.707106781
          else
            x1 = Math.sqrt(xx)
            y1 = xy / x1
            z1 = xz / x1
          end
        elsif yy > zz # m22 is the largest diagonal term
          if yy < epsilon
            x1 = 0.707106781
            y1 = 0.0
            z1 = 0.707106781
          else
            y1 = Math.sqrt(yy)
            x1 = xy / y1
            z1 = yz / y1
          end
        else # m33 is the largest diagonal term so base result on self
          if zz < epsilon
            x1 = 0.707106781
            y1 = 0.707106781
            z1 = 0.0
          else
            z1 = Math.sqrt(zz)
            x1 = xz / z1
            y1 = yz / z1
          end
        end
        @elements = [x1, y1, z1, angle]
        return self # return 180 deg rotation
      end
      # as we have reached here there are no singularities so we can handle normally
      s = Math.sqrt((m32 - m23) * (m32 - m23) +
        (m13 - m31) * (m13 - m31) +
        (m21 - m12) * (m21 - m12)) # used to normalize
      s = 1.0 if (s.abs < 0.001)
      # prevent divide by zero, should not happen if matrix is orthogonal and should be
      # caught by singularity test above, but I've left it in just in case
      @elements[0] = (m32 - m23) / s
      @elements[1] = (m13 - m31) / s
      @elements[2] = (m21 - m12) / s
      @elements[3] = Math.acos((m11 + m22 + m33 - 1.0) / 2.0)
      self
    end

    def dot(v)
      x * v.x + y * v.y + z * v.z + w * v.w
    end

    def length_manhattan
      x.abs + y.abs + z.abs + w.abs
    end

    def from_attribute(attribute, index, offset = 0)
      index = index * attribute.itemSize + offset
      @elements[0] = attribute.array[index]
      @elements[1] = attribute.array[index + 1]
      @elements[2] = attribute.array[index + 2]
      @elements[3] = attribute.array[index + 3]
      self
    end
  end
end
