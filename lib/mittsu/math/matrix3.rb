require 'mittsu/math'

module Mittsu
  class Matrix3
    attr_accessor :elements

    DIMENSIONS = 3

    def initialize()
      @elements = [
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
      ]
    end

    def set(n11, n12, n13, n21, n22, n23, n31, n32, n33)
      te = self.elements
      te[0] = n11.to_f; te[3] = n12.to_f; te[6] = n13.to_f
      te[1] = n21.to_f; te[4] = n22.to_f; te[7] = n23.to_f
      te[2] = n31.to_f; te[5] = n32.to_f; te[8] = n33.to_f
      self
    end

    def identity
      self.set(
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
      )
      self
    end

    def copy(m)
      me = m.elements
      self.set(
        me[0], me[3], me[6],
        me[1], me[4], me[7],
        me[2], me[5], me[8]
      )
      self
    end

    def apply_to_vector3_array(array, offset = 0, length = array.length)
      v1 = Mittsu::Vector3.new
      i, j = 0, offset
      while i < length
        v1.x = array[j]
        v1.y = array[j + 1]
        v1.z = array[j + 2]
        v1.apply_matrix3(self)
        array[j]     = v1.x
        array[j + 1] = v1.y
        array[j + 2] = v1.z
        i += 3
        j += 3
      end
      array
    end

    def multiply_scalar(s)
      te = self.elements
      te[0] *= s; te[3] *= s; te[6] *= s
      te[1] *= s; te[4] *= s; te[7] *= s
      te[2] *= s; te[5] *= s; te[8] *= s
      self
    end

    def determinant
      a, b, c, d, e, f, g, h, i = *self.elements
      a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g
    end

    def inverse(matrix, throw_on_invertible = false)
      # input: Mittsu::Matrix4
      # (based on http:#code.google.com/p/webgl-mjs/)
      me = matrix.elements
      te = self.elements
      te[0] =   me[10] * me[5] - me[6] * me[9]
      te[1] = - me[10] * me[1] + me[2] * me[9]
      te[2] =   me[6] * me[1] - me[2] * me[5]
      te[3] = - me[10] * me[4] + me[6] * me[8]
      te[4] =   me[10] * me[0] - me[2] * me[8]
      te[5] = - me[6] * me[0] + me[2] * me[4]
      te[6] =   me[9] * me[4] - me[5] * me[8]
      te[7] = - me[9] * me[0] + me[1] * me[8]
      te[8] =   me[5] * me[0] - me[1] * me[4]
      det = me[0] * te[0] + me[1] * te[3] + me[2] * te[6]
      # no inverse
      if det.zero?
        msg = "Mittsu::Matrix3#inverse: can't invert matrix, determinant is 0"
        if throw_on_invertible
          raise Error.new(msg)
        else
          puts "WARNING: #{msg}"
          # THREE.warn(msg)
        end
        self.identity
        return self
      end
      self.multiply_scalar(1.0 / det)
      self
    end

    def transpose
      m = self.elements
      tmp = m[1]; m[1] = m[3]; m[3] = tmp
      tmp = m[2]; m[2] = m[6]; m[6] = tmp
      tmp = m[5]; m[5] = m[7]; m[7] = tmp
      self
    end

    def flatten_to_array_offset(array, offset)
      te = self.elements
      array[offset    ] = te[0]
      array[offset + 1] = te[1]
      array[offset + 2] = te[2]
      array[offset + 3] = te[3]
      array[offset + 4] = te[4]
      array[offset + 5] = te[5]
      array[offset + 6] = te[6]
      array[offset + 7] = te[7]
      array[offset + 8]  = te[8]
      array
    end

    def normal_matrix(m)
      # input: THREE.Matrix4
      self.inverse(m).transpose
      self
    end

    def transpose_into_array(r)
      m = self.elements
      r[0] = m[0]
      r[1] = m[3]
      r[2] = m[6]
      r[3] = m[1]
      r[4] = m[4]
      r[5] = m[7]
      r[6] = m[2]
      r[7] = m[5]
      r[8] = m[8]
      self
    end

    def ==(other)
      other.elements == @elements
    end

    def from_array(array)
      self.elements[0..array.length] = (array)
      self
    end

    def to_a
      te = self.elements
      [
        te[0], te[1], te[2],
        te[3], te[4], te[5],
        te[6], te[7], te[8]
      ]
    end

    def clone
      Mittsu::Matrix3.new.from_array(self.elements)
    end

  end
end
