require 'mittsu/math'

module Mittsu
  class Vector4
    attr_accessor :x, :y, :z, :w
    def initialize(x = 0.0, y = 0.0, z = 0.0, w = 1.0)
      self.set(x, y, z, w)
    end

    def set(x, y, z, w)
      @x, @y, @z, @w = x.to_f, y.to_f, z.to_f, w.to_f
      self
    end

    def set_x(x)
      @x = x.to_f
      self
    end

    def set_y(y)
      @y = y.to_f
      self
    end

    def set_z(z)
      @z = z.to_f
      self
    end

    def set_w(w)
      @w = w.to_f
      self
    end

    def set_component(index, value)
      case index
      when 0 then @x = value.to_f
      when 1 then @y = value.to_f
      when 2 then @z = value.to_f
      when 3 then @w = value.to_f
      else raise IndexError.new
      end
    end

    def get_component(index)
      case index
      when 0 then return @x
      when 1 then return @y
      when 2 then return @z
      when 3 then return @w
      else raise IndexError.new
      end
    end

    def copy(v)
      @x = v.x
      @y = v.y
      @z = v.z
      @w = v.w || 1.0
      self
    end

    def add(v)
      @x += v.x
      @y += v.y
      @z += v.z
      @w += v.w
      self
    end

    def add_scalar(s)
      @x += s
      @y += s
      @z += s
      @w += s
      self
    end

    def add_vectors(a, b)
      @x = a.x + b.x
      @y = a.y + b.y
      @z = a.z + b.z
      @w = a.w + b.w
      self
    end

    def sub(v)
      @x -= v.x
      @y -= v.y
      @z -= v.z
      @w -= v.w
      self
    end

    def sub_scalar(s)
      @x -= s
      @y -= s
      @z -= s
      @w -= s
      self
    end

    def sub_vectors(a, b)
      @x = a.x - b.x
      @y = a.y - b.y
      @z = a.z - b.z
      @w = a.w - b.w
      self
    end

    def multiply_scalar(scalar)
      @x *= scalar
      @y *= scalar
      @z *= scalar
      @w *= scalar
      self
    end

    def apply_matrix4(m)
      x1, y1, z1, w1 = @x, @y, @z, @w
      e = m.elements
      @x = e[0] * x1 + e[4] * y1 + e[8] * z1 + e[12] * w1
      @y = e[1] * x1 + e[5] * y1 + e[9] * z1 + e[13] * w1
      @z = e[2] * x1 + e[6] * y1 + e[10] * z1 + e[14] * w1
      @w = e[3] * x1 + e[7] * y1 + e[11] * z1 + e[15] * w1
      self
    end

    def divide_scalar(scalar)
      if scalar != 0.0
        inv_scalar = 1.0 / scalar
        @x *= inv_scalar
        @y *= inv_scalar
        @z *= inv_scalar
        @w *= inv_scalar
      else
        @x, @y, @z, @w = 0.0, 0.0, 0.0, 1.0
      end
      self
    end

    def set_axis_angle_from_quaternion(q)
      # http:#www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle/index.htm
      # q is assumed to be normalized
      @w = 2.0 * Math.acos(q.w)
      s = Math.sqrt(1.0 - q.w * q.w)
      if s < 0.0001
         @x = 1.0
         @y = 0.0
         @z = 0.0
      else
         @x = q.x / s
         @y = q.y / s
         @z = q.z / s
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
          self.set(1, 0, 0, 0)
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
        self.set(x1, y1, z1, angle)
        return self # return 180 deg rotation
      end
      # as we have reached here there are no singularities so we can handle normally
      s = Math.sqrt((m32 - m23) * (m32 - m23) +
        (m13 - m31) * (m13 - m31) +
        (m21 - m12) * (m21 - m12)) # used to normalize
      s = 1.0 if (s.abs < 0.001)
      # prevent divide by zero, should not happen if matrix is orthogonal and should be
      # caught by singularity test above, but I've left it in just in case
      @x = (m32 - m23) / s
      @y = (m13 - m31) / s
      @z = (m21 - m12) / s
      @w = Math.acos((m11 + m22 + m33 - 1.0) / 2.0)
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
      if @w > v.w
        @w = v.w
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
      if @w < v.w
        @w = v.w
      end
      self
    end

    def clamp(min, max)
      # This function assumes min < max, if self assumption isn't true it will not operate correctly
      if @x < min.x
        @x = min.x
      elsif @x > max.x
        @x = max.x
      end
      if @y < min.y
        @y = min.y
      elsif @y > max.y
        @y = max.y
      end
      if @z < min.z
        @z = min.z
      elsif @z > max.z
        @z = max.z
      end
      if @w < min.w
        @w = min.w
      elsif @w > max.w
        @w = max.w
      end
      self
    end

    def floor
      @x = (@x).floor
      @y = (@y).floor
      @z = (@z).floor
      @w = (@w).floor
      self
    end

    def ceil
      @x = (@x).ceil
      @y = (@y).ceil
      @z = (@z).ceil
      @w = (@w).ceil
      self
    end

    def round
      @x = (@x).round
      @y = (@y).round
      @z = (@z).round
      @w = (@w).round
      self
    end

    def round_to_zero
      @x = (@x < 0) ? (@x).ceil : (@x).floor
      @y = (@y < 0) ? (@y).ceil : (@y).floor
      @z = (@z < 0) ? (@z).ceil : (@z).floor
      @w = (@w < 0) ? (@w).ceil : (@w).floor
      self
    end

    def negate
      @x = - @x
      @y = - @y
      @z = - @z
      @w = - @w
      self
    end

    def dot(v)
      @x * v.x + @y * v.y + @z * v.z + @w * v.w
    end

    def length_sq
      @x * @x + @y * @y + @z * @z + @w * @w
    end

    def length
      Math.sqrt(@x * @x + @y * @y + @z * @z + @w * @w)
    end

    def length_manhattan
      (@x).abs + (@y).abs + (@z).abs + (@w).abs
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
      @w += (v.w - @w) * alpha
      self
    end

    def lerp_vectors(v1, v2, alpha)
      self.sub_vectors(v2, v1).multiply_scalar(alpha).add(v1)
      self
    end

    def ==(v)
      ((v.x == @x) && (v.y == @y) && (v.z == @z) && (v.w == @w))
    end

    def []=(index, value)
      return @x = value.to_f if index == 0 || index == :x
      return @y = value.to_f if index == 1 || index == :y
      return @z = value.to_f if index == 2 || index == :z
      return @w = value.to_f if index == 3 || index == :w
      raise IndexError
    end

    def [](index)
      return @x if index == 0 || index == :x
      return @y if index == 1 || index == :y
      return @z if index == 2 || index == :z
      return @w if index == 3 || index == :w
      raise IndexError
    end

    def from_array(array, offset = 0)
      @x = array[offset]
      @y = array[offset + 1]
      @z = array[offset + 2]
      @w = array[offset + 3]
      self
    end

    def to_array(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array[offset + 2] = @z
      array[offset + 3] = @w
      array
    end
    alias :to_a :to_array

    def from_attribute(attribute, index, offset = 0)
      index = index * attribute.itemSize + offset
      @x = attribute.array[index]
      @y = attribute.array[index + 1]
      @z = attribute.array[index + 2]
      @w = attribute.array[index + 3]
      self
    end

    def clone
      Mittsu::Vector4.new @x, @y, @z, @w
    end

    def to_s
      "[#{x}, #{y}, #{z}, #{w}]"
    end
  end
end
