require 'mittsu/math'

module Mittsu
  class Matrix4
    attr_accessor :elements

    def initialize()
      @elements = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ]
    end

    def set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44)
      te = self.elements
      te[0] = n11.to_f; te[4] = n12.to_f; te[8] = n13.to_f; te[12] = n14.to_f
      te[1] = n21.to_f; te[5] = n22.to_f; te[9] = n23.to_f; te[13] = n24.to_f
      te[2] = n31.to_f; te[6] = n32.to_f; te[10] = n33.to_f; te[14] = n34.to_f
      te[3] = n41.to_f; te[7] = n42.to_f; te[11] = n43.to_f; te[15] = n44.to_f
      self
    end

    def identity
      self.set(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      )
      self
    end

    def copy(m)
      self.from_array(m.elements)
      self
    end

    def copy_position(m)
      te = self.elements
      me = m.elements
      te[12] = me[12]
      te[13] = me[13]
      te[14] = me[14]
      self
    end

    def extract_basis(xAxis, yAxis, zAxis)
      te = self.elements
      xAxis.set(te[0], te[1], te[2])
      yAxis.set(te[4], te[5], te[6])
      zAxis.set(te[8], te[9], te[10])
      self
    end

    def make_basis(xAxis, yAxis, zAxis)
      self.set(
        xAxis.x, yAxis.x, zAxis.x, 0.0,
        xAxis.y, yAxis.y, zAxis.y, 0.0,
        xAxis.z, yAxis.z, zAxis.z, 0.0,
            0.0,     0.0,     0.0, 1.0
      )
      self
    end

    def extract_rotation(m)
      v1 = Mittsu::Vector3.new
      te = self.elements
      me = m.elements
      scale_x = 1.0 / v1.set(me[0], me[1], me[2]).length
      scale_y = 1.0 / v1.set(me[4], me[5], me[6]).length
      scale_z = 1.0 / v1.set(me[8], me[9], me[10]).length
      te[0] = me[0] * scale_x
      te[1] = me[1] * scale_x
      te[2] = me[2] * scale_x
      te[4] = me[4] * scale_y
      te[5] = me[5] * scale_y
      te[6] = me[6] * scale_y
      te[8] = me[8] * scale_z
      te[9] = me[9] * scale_z
      te[10] = me[10] * scale_z
      self
    end

    def make_rotation_from_euler(euler)
      te = self.elements
      x, y, z = euler.x, euler.y, euler.z
      a, b = Math.cos(x), Math.sin(x)
      c, d = Math.cos(y), Math.sin(y)
      e, f = Math.cos(z), Math.sin(z)
      if euler.order == 'XYZ'
        ae = a * e; af = a * f; be = b * e; bf = b * f
        te[0] = c * e
        te[4] = - c * f
        te[8] = d
        te[1] = af + be * d
        te[5] = ae - bf * d
        te[9] = - b * c
        te[2] = bf - ae * d
        te[6] = be + af * d
        te[10] = a * c
      elsif euler.order == 'YXZ'
        ce = c * e; cf = c * f; de = d * e; df = d * f
        te[0] = ce + df * b
        te[4] = de * b - cf
        te[8] = a * d
        te[1] = a * f
        te[5] = a * e
        te[9] = - b
        te[2] = cf * b - de
        te[6] = df + ce * b
        te[10] = a * c
      elsif euler.order == 'ZXY'
        ce = c * e; cf = c * f; de = d * e; df = d * f
        te[0] = ce - df * b
        te[4] = - a * f
        te[8] = de + cf * b
        te[1] = cf + de * b
        te[5] = a * e
        te[9] = df - ce * b
        te[2] = - a * d
        te[6] = b
        te[10] = a * c
      elsif euler.order == 'ZYX'
        ae = a * e; af = a * f; be = b * e; bf = b * f
        te[0] = c * e
        te[4] = be * d - af
        te[8] = ae * d + bf
        te[1] = c * f
        te[5] = bf * d + ae
        te[9] = af * d - be
        te[2] = - d
        te[6] = b * c
        te[10] = a * c
      elsif euler.order == 'YZX'
        ac = a * c; ad = a * d; bc = b * c; bd = b * d
        te[0] = c * e
        te[4] = bd - ac * f
        te[8] = bc * f + ad
        te[1] = f
        te[5] = a * e
        te[9] = - b * e
        te[2] = - d * e
        te[6] = ad * f + bc
        te[10] = ac - bd * f
      elsif euler.order == 'XZY'
        ac = a * c; ad = a * d; bc = b * c; bd = b * d
        te[0] = c * e
        te[4] = - f
        te[8] = d * e
        te[1] = ac * f + bd
        te[5] = a * e
        te[9] = ad * f - bc
        te[2] = bc * f - ad
        te[6] = b * e
        te[10] = bd * f + ac
      end
      # last column
      te[3] = 0.0
      te[7] = 0.0
      te[11] = 0.0
      # bottom row
      te[12] = 0.0
      te[13] = 0.0
      te[14] = 0.0
      te[15] = 1.0
      self
    end

    def make_rotation_from_quaternion(q)
      te = self.elements
      x, y, z, w = q.x, q.y, q.z, q.w
      x2, y2, z2 = x + x, y + y, z + z
      xx, xy, xz = x * x2, x * y2, x * z2
      yy, yz, zz = y * y2, y * z2, z * z2
      wx, wy, wz = w * x2, w * y2, w * z2
      te[0] = 1.0 - (yy + zz)
      te[4] = xy - wz
      te[8] = xz + wy
      te[1] = xy + wz
      te[5] = 1.0 - (xx + zz)
      te[9] = yz - wx
      te[2] = xz - wy
      te[6] = yz + wx
      te[10] = 1.0 - (xx + yy)
      # last column
      te[3] = 0.0
      te[7] = 0.0
      te[11] = 0.0
      # bottom row
      te[12] = 0.0
      te[13] = 0.0
      te[14] = 0.0
      te[15] = 1.0
      self
    end

    def look_at(eye, target, up)
      x = Mittus::Vector3.new
      y = Mittus::Vector3.new
      z = Mittus::Vector3.new
      te = self.elements
      z.sub_vectors(eye, target).normalize
      if z.length.zero?
        z.z = 1
      end
      x.cross_vectors(up, z).normalize
      if x.length.zero?
        z.x += 0.0001
        x.cross_vectors(up, z).normalize
      end
      y.cross_vectors(z, x)
      te[0] = x.x; te[4] = y.x; te[8] = z.x
      te[1] = x.y; te[5] = y.y; te[9] = z.y
      te[2] = x.z; te[6] = y.z; te[10] = z.z
      self
    end

    def multiply(m)
      self.multiply_matrices(self, m)
    end

    def multiply_matrices(a, b)
      ae = a.elements
      be = b.elements
      te = self.elements
      a11 = ae[0]; a12 = ae[4]; a13 = ae[8];  a14 = ae[12]
      a21 = ae[1]; a22 = ae[5]; a23 = ae[9];  a24 = ae[13]
      a31 = ae[2]; a32 = ae[6]; a33 = ae[10]; a34 = ae[14]
      a41 = ae[3]; a42 = ae[7]; a43 = ae[11]; a44 = ae[15]
      b11 = be[0]; b12 = be[4]; b13 = be[8];  b14 = be[12]
      b21 = be[1]; b22 = be[5]; b23 = be[9];  b24 = be[13]
      b31 = be[2]; b32 = be[6]; b33 = be[10]; b34 = be[14]
      b41 = be[3]; b42 = be[7]; b43 = be[11]; b44 = be[15]
      te[0]  = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41
      te[4]  = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42
      te[8]  = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43
      te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44
      te[1]  = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41
      te[5]  = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42
      te[9]  = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43
      te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44
      te[2]  = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41
      te[6]  = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42
      te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43
      te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44
      te[3]  = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41
      te[7]  = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42
      te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43
      te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44
      self
    end

    def multiply_to_array(a, b, r)
      te = self.elements
      self.multiply_matrices(a, b)
      r[0]  = te[0];  r[1]  = te[1];  r[2]  = te[2];  r[3]  = te[3]
      r[4]  = te[4];  r[5]  = te[5];  r[6]  = te[6];  r[7]  = te[7]
      r[8]  = te[8];  r[9]  = te[9];  r[10] = te[10]; r[11] = te[11]
      r[12] = te[12]; r[13] = te[13]; r[14] = te[14]; r[15] = te[15]
      self
    end

    def multiply_scalar(s)
      te = self.elements
      s = s.to_f
      te[0] *= s; te[4] *= s; te[8]  *= s; te[12] *= s
      te[1] *= s; te[5] *= s; te[9]  *= s; te[13] *= s
      te[2] *= s; te[6] *= s; te[10] *= s; te[14] *= s
      te[3] *= s; te[7] *= s; te[11] *= s; te[15] *= s
      self
    end

    def apply_to_vector3_array(array, offset = 0, length = array.length)
      v1 = Mittsu::Vector3.new
      i = 0
      j = offset
      while i < length
        v1.x = array[j]
        v1.y = array[j + 1]
        v1.z = array[j + 2]
        v1.apply_matrix4(self)
        array[j]     = v1.x
        array[j + 1] = v1.y
        array[j + 2] = v1.z
        i += 3
        j += 3
      end
      array
    end

    def determinant
      te = self.elements
      n11 = te[0]; n12 = te[4]; n13 = te[8]; n14 = te[12]
      n21 = te[1]; n22 = te[5]; n23 = te[9]; n24 = te[13]
      n31 = te[2]; n32 = te[6]; n33 = te[10]; n34 = te[14]
      n41 = te[3]; n42 = te[7]; n43 = te[11]; n44 = te[15]
      #TODO: make this more efficient
      #(based on http:#www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm)
      n41 * (n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34) +
      n42 * (n11 * n23 * n34 - n11 * n24 * n33 + n14 * n21 * n33 - n13 * n21 * n34 + n13 * n24 * n31 - n14 * n23 * n31) +
      n43 * (n11 * n24 * n32 - n11 * n22 * n34 - n14 * n21 * n32 + n12 * n21 * n34 + n14 * n22 * n31 - n12 * n24 * n31) +
      n44 * (-n13 * n22 * n31 - n11 * n23 * n32 + n11 * n22 * n33 + n13 * n21 * n32 - n12 * n21 * n33 + n12 * n23 * n31)
    end

    def transpose
      te = self.elements
      tmp = te[1];  te[1]  = te[4];  te[4]  = tmp
      tmp = te[2];  te[2]  = te[8];  te[8]  = tmp
      tmp = te[6];  te[6]  = te[9];  te[9]  = tmp
      tmp = te[3];  te[3]  = te[12]; te[12] = tmp
      tmp = te[7];  te[7]  = te[13]; te[13] = tmp
      tmp = te[11]; te[11] = te[14]; te[14] = tmp
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
      array[offset + 9]  = te[9]
      array[offset + 10] = te[10]
      array[offset + 11] = te[11]
      array[offset + 12] = te[12]
      array[offset + 13] = te[13]
      array[offset + 14] = te[14]
      array[offset + 15] = te[15]
      array
    end

    def set_position(v)
      te = self.elements
      te[12] = v.x
      te[13] = v.y
      te[14] = v.z
      self
    end

    def inverse(m, throw_on_invertable = false)
      # based on http:#www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm
      te = @elements
      me = m.elements
      n11 = me[0]; n12 = me[4]; n13 = me[8];  n14 = me[12]
      n21 = me[1]; n22 = me[5]; n23 = me[9];  n24 = me[13]
      n31 = me[2]; n32 = me[6]; n33 = me[10]; n34 = me[14]
      n41 = me[3]; n42 = me[7]; n43 = me[11]; n44 = me[15]
      te[0] = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44
      te[4] = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44
      te[8] = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44
      te[12] = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34
      te[1] = n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44
      te[5] = n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44
      te[9] = n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44
      te[13] = n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34
      te[2] = n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44
      te[6] = n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44
      te[10] = n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44
      te[14] = n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34
      te[3] = n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43
      te[7] = n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43
      te[11] = n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43
      te[15] = n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33
      det = n11 * te[0] + n21 * te[4] + n31 * te[8] + n41 * te[12]
      if det.zero?
        msg = "Mittsu::Matrix4#inverse: can't invert matrix, determinant is 0"
        if throw_on_invertable
          raise Error.new(msg)
        else
          # THREE.warn(msg)
          puts "WARNING: #{msg}"
        end
        self.identity
        return self
      end
      self.multiply_scalar(1.0 / det)
      self
    end

    def scale(v)
      te = self.elements
      x = v.x; y = v.y; z = v.z
      te[0] *= x; te[4] *= y; te[8]  *= z
      te[1] *= x; te[5] *= y; te[9]  *= z
      te[2] *= x; te[6] *= y; te[10] *= z
      te[3] *= x; te[7] *= y; te[11] *= z
      self
    end

    def max_scale_on_axis
      te = self.elements
      scale_x_sq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2]
      scale_y_sq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6]
      scale_z_sq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10]
      Math.sqrt([scale_x_sq, scale_y_sq, scale_z_sq].max)
    end

    def make_translation(x, y, z)
      self.set(
        1.0, 0.0, 0.0, x,
        0.0, 1.0, 0.0, y,
        0.0, 0.0, 1.0, z,
        0.0, 0.0, 0.0, 1.0
      )
      self
    end

    def make_rotation_x(theta)
      c, s = Math.cos(theta), Math.sin(theta)
      self.set(
        1.0, 0.0,  0.0, 0.0,
        0.0,   c,   -s, 0.0,
        0.0,   s,    c, 0.0,
        0.0, 0.0,  0.0, 1.0
      )
      self
    end

    def make_rotation_y(theta)
      c, s = Math.cos(theta), Math.sin(theta)
      self.set(
           c, 0.0,   s, 0.0,
         0.0, 1.0, 0.0, 0.0,
          -s, 0.0,   c, 0.0,
         0.0, 0.0, 0.0, 1.0
      )
      self
    end

    def make_rotation_z(theta)
      c, s = Math.cos(theta), Math.sin(theta)
      self.set(
          c,   -s, 0.0, 0.0,
          s,    c, 0.0, 0.0,
        0.0,  0.0, 1.0, 0.0,
        0.0,  0.0, 0.0, 1.0
      )
      self
    end

    def make_rotation_axis(axis, angle)
      # Based on http:#www.gamedev.net/reference/articles/article1199.asp
      c = Math.cos(angle)
      s = Math.sin(angle)
      t = 1.0 - c
      x = axis.x, y = axis.y, z = axis.z
      tx = t * x, ty = t * y
      self.set(
            tx * x + c, tx * y - s * z, tx * z + s * y, 0.0,
        tx * y + s * z,     ty * y + c, ty * z - s * x, 0.0,
        tx * z - s * y, ty * z + s * x,  t * z * z + c, 0.0,
                   0.0,            0.0,            0.0, 1.0
      )
      self
    end

    def make_scale(x, y, z)
      self.set(
        x.to_f, 0.0,    0.0,    0.0,
        0.0,    y.to_f, 0.0,    0.0,
        0.0,    0.0,    z.to_f, 0.0,
        0.0,    0.0,    0.0,    1.0
      )
      self
    end

    def compose(position, quaternion, scale)
      self.make_rotation_from_quaternion(quaternion)
      self.scale(scale)
      self.set_position(position)
      self
    end

    def decompose(position, quaternion, scale)
      vector = Mittsu::Vector3.new
      matrix = Mittsu::Matrix4.new
      te = self.elements
      sx = vector.set(te[0], te[1],  te[2]).length
      sy = vector.set(te[4], te[5],  te[6]).length
      sz = vector.set(te[8], te[9], te[10]).length
      # if determine is negative, we need to invert one scale
      det = self.determinant
      if det < 0.0
        sx = -sx
      end
      position.x = te[12]
      position.y = te[13]
      position.z = te[14]
      # scale the rotation part
      matrix.elements[0...15] = self.elements # at this point matrix is incomplete so we can't use .copy
      inv_sx = 1.0 / sx
      inv_sy = 1.0 / sy
      inv_sz = 1.0 / sz
      matrix.elements[0]  *= inv_sx
      matrix.elements[1]  *= inv_sx
      matrix.elements[2]  *= inv_sx
      matrix.elements[4]  *= inv_sy
      matrix.elements[5]  *= inv_sy
      matrix.elements[6]  *= inv_sy
      matrix.elements[8]  *= inv_sz
      matrix.elements[9]  *= inv_sz
      matrix.elements[10] *= inv_sz
      quaternion.set_from_rotation_matrix(matrix)
      scale.x = sx
      scale.y = sy
      scale.z = sz
      self
    end

    def make_frustum(left, right, bottom, top, near, far)
      left, right, bottom, top, near, far =
        left.to_f, right.to_f, bottom.to_f, top.to_f, near.to_f, far.to_f
      te = self.elements
      x = 2.0 * near / (right - left)
      y = 2.0 * near / (top - bottom)
      a = (right + left) / (right - left)
      b = (top + bottom) / (top - bottom)
      c =     -(far + near) / (far - near)
      d = -2.0 * far * near / (far - near)
      te[0] =   x; te[4] = 0.0;  te[8]  =    a;  te[12] = 0.0
      te[1] = 0.0; te[5] =   y;  te[9]  =    b;  te[13] = 0.0
      te[2] = 0.0; te[6] = 0.0;  te[10] =    c;  te[14] =   d
      te[3] = 0.0; te[7] = 0.0;  te[11] = -1.0;  te[15] = 0.0
      self
    end

    def make_perspective(fov, aspect, near, far)
      fov, aspect, near, far =
        fov.to_f, aspect.to_f, near.to_f, far.to_f
      ymax = near * Math.tan(Math.deg_to_rad(fov * 0.5))
      ymin = -ymax
      xmin = ymin * aspect
      xmax = ymax * aspect
      self.make_frustum(xmin, xmax, ymin, ymax, near, far)
    end

    def make_orthographic(left, right, top, bottom, near, far)
      left, right, top, bottom, near, far =
        left.to_f, right.to_f, top.to_f, bottom.to_f, near.to_f, far.to_f
      te = self.elements
      w = right - left
      h = top - bottom
      p = far - near
      x = (right + left) / w
      y = (top + bottom) / h
      z = (far + near) / p
      te[0] = 2.0 / w; te[4] =     0.0; te[8]  =      0.0; te[12] =  -x
      te[1] =     0.0; te[5] = 2.0 / h; te[9]  =      0.0; te[13] =  -y
      te[2] =     0.0; te[6] =     0.0; te[10] = -2.0 / p; te[14] =  -z
      te[3] =     0.0; te[7] =     0.0; te[11] =      0.0; te[15] = 1.0
      self
    end

    def from_array(array)
      self.elements[0..array.length] = array
      self
    end

    def to_a
      te = self.elements
      [
        te[0], te[1], te[2], te[3],
        te[4], te[5], te[6], te[7],
        te[8], te[9], te[10], te[11],
        te[12], te[13], te[14], te[15]
      ]
    end

    def clone
      Mittsu::Matrix4.new.from_array(self.elements)
    end

  end
end
