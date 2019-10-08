module Mittsu
  class Euler
    RotationOrders = [ 'XYZ', 'YZX', 'ZXY', 'XZY', 'YXZ', 'ZYX' ]
    DefaultOrder = 'XYZ'

    attr_reader :x, :y, :z, :order

    def initialize(x = 0.0, y = 0.0, z = 0.0, order = DefaultOrder)
      @x, @y, @z, @order = x.to_f, y.to_f, z.to_f, order
      @on_change_callback = false
    end

    def set(x, y, z, order = nil)
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
      @order = order || @order
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

    def order=(order)
      @order = order
      self.on_change_callback
    end

    def copy(euler)
      @x = euler.x
      @y = euler.y
      @z = euler.z
      @order = euler.order
      self.on_change_callback
      self
    end

    def set_from_rotation_matrix(m, order, update = true)
      # assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
      te = m.elements
      m11 = te[0]; m12 = te[4]; m13 = te[8]
      m21 = te[1]; m22 = te[5]; m23 = te[9]
      m31 = te[2]; m32 = te[6]; m33 = te[10]
      order = order || @order
      if order == 'XYZ'
        @y = Math.asin(Math.clamp(m13, -1.0, 1.0))
        if m13.abs < 0.99999
          @x = Math.atan2(- m23, m33)
          @z = Math.atan2(- m12, m11)
        else
          @x = Math.atan2(m32, m22)
          @z = 0.0
        end
      elsif order == 'YXZ'
        @x = Math.asin(- Math.clamp(m23, -1.0, 1.0))
        if m23.abs < 0.99999
          @y = Math.atan2(m13, m33)
          @z = Math.atan2(m21, m22)
        else
          @y = Math.atan2(- m31, m11)
          @z = 0.0
        end
      elsif order == 'ZXY'
        @x = Math.asin(Math.clamp(m32, -1.0, 1.0))
        if m32.abs < 0.99999
          @y = Math.atan2(- m31, m33)
          @z = Math.atan2(- m12, m22)
        else
          @y = 0.0
          @z = Math.atan2(m21, m11)
        end
      elsif order == 'ZYX'
        @y = Math.asin(- Math.clamp(m31, -1.0, 1.0))
        if m31.abs < 0.99999
          @x = Math.atan2(m32, m33)
          @z = Math.atan2(m21, m11)
        else
          @x = 0.0
          @z = Math.atan2(- m12, m22)
        end
      elsif order == 'YZX'
        @z = Math.asin(Math.clamp(m21, -1.0, 1.0))
        if m21.abs < 0.99999
          @x = Math.atan2(- m23, m22)
          @y = Math.atan2(- m31, m11)
        else
          @x = 0.0
          @y = Math.atan2(m13, m33)
        end
      elsif order == 'XZY'
        @z = Math.asin(- Math.clamp(m12, -1.0, 1.0))
        if m12.abs < 0.99999
          @x = Math.atan2(m32, m22)
          @y = Math.atan2(m13, m11)
        else
          @x = Math.atan2(- m23, m33)
          @y = 0.0
        end
      else
        puts("WARNING: Mittsu::Euler#set_from_rotation_matrix given unsupported order: #{order}")
      end
      @order = order
      self.on_change_callback if update
      self
    end

    def set_from_quaternion(q, order, update = true)
      matrix = Mittsu::Matrix4.new
      matrix.make_rotation_from_quaternion(q)
      self.set_from_rotation_matrix(matrix, order, update)
      self
    end

    def set_from_vector3(v, order)
      self.set(v.x, v.y, v.z, order || @order)
    end

    def reorder(new_order)
      # WARNING: this discards revolution information -bhouston
      q = Mittsu::Quaternion.new.set_from_euler(self)
      self.set_from_quaternion(q, new_order)
    end

    def ==(euler)
      (euler.x == @x) && (euler.y == @y) && (euler.z == @z) && (euler.order == @order)
    end

    def from_array(array)
      @x = array[0]
      @y = array[1]
      @z = array[2]
      @order = array[3] unless array[3].nil?
      self.on_change_callback
      self
    end

    def to_a(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array[offset + 2] = @z
      array[offset + 3] = @order
      array
    end

    def to_vector3(optional_result = nil)
      if optional_result
        return optional_result.set(@x, @y, @z)
      else
        return Mittsu::Vector3.new(@x, @y, @z)
      end
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
      Mittsu::Euler.new(@x, @y, @z, @order)
    end

  end
end
