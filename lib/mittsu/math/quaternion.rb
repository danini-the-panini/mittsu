require 'mittsu/math'

module Mittsu
  class Quaternion
    EPS = 0.000001

    attr_reader :x, :y, :z, :w

    def initialize(x = 0.0, y = 0.0, z = 0.0, w = 1.0)
      @x, @y, @z, @w = x, y, z, w
    end

    def set(x, y, z, w)
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
      @w = w.to_f
      self.on_change_callback
      self
    end

    def x=(x)
      @x = x.to_f
      self.on_change_callback
    end

    def y=(y)
      @y = y.to_f
      self.on_change_callback
    end

    def z=(z)
      @z = z.to_f
      self.on_change_callback
    end

    def w=(w)
      @w = w.to_f
      self.on_change_callback
    end

    def copy(quaternion)
      @x = quaternion.x
      @y = quaternion.y
      @z = quaternion.z
      @w = quaternion.w
      self.on_change_callback
      self
    end

    def set_from_euler(euler, update = true)
      # http:#www.mathworks.com/matlabcentral/fileexchange/
      #   20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
      #  content/SpinCalc.m
      c1 = Math.cos(euler.x / 2.0)
      c2 = Math.cos(euler.y / 2.0)
      c3 = Math.cos(euler.z / 2.0)
      s1 = Math.sin(euler.x / 2.0)
      s2 = Math.sin(euler.y / 2.0)
      s3 = Math.sin(euler.z / 2.0)
      if euler.order == 'XYZ'
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      elsif euler.order == 'YXZ'
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      elsif euler.order == 'ZXY'
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      elsif euler.order == 'ZYX'
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      elsif euler.order == 'YZX'
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      elsif euler.order == 'XZY'
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      end
      self.on_change_callback if update
      self
    end

    def set_from_axis_angle(axis, angle)
      # http:#www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm
      # assumes axis is normalized
      half_angle = angle / 2.0
      s = Math.sin(half_angle)
      @x = axis.x * s
      @y = axis.y * s
      @z = axis.z * s
      @w = Math.cos(half_angle)
      self.on_change_callback
      self
    end

    def set_from_rotation_matrix(m)
      # http:#www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
      # assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
      te = m.elements
      m11 = te[0]; m12 = te[4]; m13 = te[8]
      m21 = te[1]; m22 = te[5]; m23 = te[9]
      m31 = te[2]; m32 = te[6]; m33 = te[10]
      trace = m11 + m22 + m33
      if trace > 0
        s = 0.5 / Math.sqrt(trace + 1.0)
        @w = 0.25 / s
        @x = (m32 - m23) * s
        @y = (m13 - m31) * s
        @z = (m21 - m12) * s
      elsif m11 > m22 && m11 > m33
        s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33)
        @w = (m32 - m23) / s
        @x = 0.25 * s
        @y = (m12 + m21) / s
        @z = (m13 + m31) / s
      elsif m22 > m33
        s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33)
        @w = (m13 - m31) / s
        @x = (m12 + m21) / s
        @y = 0.25 * s
        @z = (m23 + m32) / s
      else
        s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22)
        @w = (m21 - m12) / s
        @x = (m13 + m31) / s
        @y = (m23 + m32) / s
        @z = 0.25 * s
      end
      self.on_change_callback
      self
    end

    def set_from_unit_vectors(v_from, v_to)
      # http:#lolengine.net/blog/2014/02/24/quaternion-from-two-vectors-final
      # assumes direction vectors v_from and v_to are normalized
      v1 = Mittsu::Vector3.new
      r = v_from.dot(v_to) + 1.0
      if r < EPS
        r = 0.0
        if v_from.x.abs > v_from.z.abs
          v1.set(-v_from.y, v_from.x, 0.0)
        else
          v1.set(0.0, -v_from.z, v_from.y)
        end
      else
        v1.cross_vectors(v_from, v_to)
      end
      @x = v1.x
      @y = v1.y
      @z = v1.z
      @w = r
      self.normalize
      self
    end

    def inverse
      self.conjugate.normalize
      self
    end

    def conjugate
      @x *= -1.0
      @y *= -1.0
      @z *= -1.0
      self.on_change_callback
      self
    end

    def dot(v)
      @x * v._x + @y * v._y + @z * v._z + @w * v._w
    end

    def length_sq
      @x * @x + @y * @y + @z * @z + @w * @w
    end

    def length
      Math.sqrt(@x * @x + @y * @y + @z * @z + @w * @w)
    end

    def normalize
      l = self.length
      if l == 0.0
        @x = 0.0
        @y = 0.0
        @z = 0.0
        @w = 1.0
      else
        l = 1.0 / l
        @x = @x * l
        @y = @y * l
        @z = @z * l
        @w = @w * l
      end
      self.on_change_callback
      self
    end

    def multiply(q)
      self.multiply_quaternions(self, q)
    end

    def multiply_quaternions(a, b)
      # from http:#www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm
      qax = a.x; qay = a.y; qaz = a.z; qaw = a.w
      qbx = b.x; qby = b.y; qbz = b.z; qbw = b.w
      @x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
      @y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
      @z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
      @w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz
      self.on_change_callback
      self
    end

    def slerp(qb, t)
      return self if t.zero?
      return self.copy(qb) if t == 1.0
      _x, _y, _z, _w = @x, @y, @z, @w
      # http:#www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/
      cos_half_theta = _w * qb.w + _x * qb.x + _y * qb.y + _z * qb.z
      if cos_half_theta < 0.0
        @w = -qb.w
        @x = -qb.x
        @y = -qb.y
        @z = -qb.z
        cos_half_theta = - cos_half_theta
      else
        self.copy(qb)
      end
      if cos_half_theta >= 1.0
        @w = _w
        @x = _x
        @y = _y
        @z = _z
        return self
      end
      half_theta = Math.acos(cos_half_theta)
      sin_half_theta = Math.sqrt(1.0 - cos_half_theta * cos_half_theta)
      if sin_half_theta.abs < 0.001
        @w = 0.5 * (_w + @w)
        @x = 0.5 * (_x + @x)
        @y = 0.5 * (_y + @y)
        @z = 0.5 * (_z + @z)
        return self
      end
      ratio_a = Math.sin((1.0. - t) * half_theta) / sin_half_theta,
      ratio_b = Math.sin(t * half_theta) / sin_half_theta
      @w = (_w * ratio_a + @w * ratio_b)
      @x = (_x * ratio_a + @x * ratio_b)
      @y = (_y * ratio_a + @y * ratio_b)
      @z = (_z * ratio_a + @z * ratio_b)
      self.on_change_callback
      self
    end

    def ==(quaternion)
      (quaternion.x == @x) && (quaternion.y == @y) && (quaternion.z == @z) && (quaternion.w == @w)
    end

    def from_array(array, offset = 0)
      @x = array[offset]
      @y = array[offset + 1]
      @z = array[offset + 2]
      @w = array[offset + 3]
      self.on_change_callback
      self
    end

    def to_array(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array[offset + 2] = @z
      array[offset + 3] = @w
      array
    end

    def on_change(&callback)
      @on_change_callback = callback
      self
    end

    def on_change_callback
      return unless @on_change_callback
      @on_change_callback.call
    end

    def clone
      Mittsu::Quaternion.new(@x, @y, @z, @w)
    end

    def self.slerp(qa, qb, qm, t)
      qm.copy(qa).slerp(qb, t)
    end

  end
end
