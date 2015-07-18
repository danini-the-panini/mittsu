require 'mittsu/math'

module Mittsu
  class Vector2
    attr_reader :x, :y

    def initialize(x = 0, y = 0)
      @x = x.to_f
      @y = y.to_f
    end

    def x=(value)
      @x = value.to_f
    end

    def y=(value)
      @y = value
    end

    def set(x, y)
      @x = x.to_f
      @y = y.to_f
      self
    end

    def []=(index, value)
      return @x = value.to_f if index == 0
      return @y = value.to_f if index == 1
      raise IndexError
    end

    def [](index)
      return @x if index == 0
      return @y if index == 1
      raise IndexError
    end

    def copy(v)
      @x = v.x
      @y = v.y
      self
    end

    def add(v)
      @x += v.x
      @y += v.y
      self
    end

    def add_scalar(s)
      @x += s
      @y += s
      self
    end

    def add_vectors(a, b)
      @x = a.x + b.x
      @y = a.y + b.y
      self
    end

    def sub(v)
      @x -= v.x
      @y -= v.y
      self
    end

    def sub_scalar(s)
      @x -= s
      @y -= s
      self
    end

    def sub_vectors(a, b)
      @x = a.x - b.x
      @y = a.y - b.y
      self
    end

    def multiply(v)
      @x *= v.x
      @y *= v.y
      self
    end

    def multiply_scalar(s)
      @x *= s
      @y *= s
      self
    end

    def divide(v)
      @x /= v.x
      @y /= v.y
      self
    end

    def divide_scalar(s)
      @x /= s
      @y /= s
      self
    end

    def min(v)
      @x = [@x, v.x].min
      @y = [@y, v.y].min
      self
    end

    def max(v)
      @x = [@x, v.x].max
      @y = [@y, v.y].max
      self
    end

    def clamp(min, max)
      @x = Math.clamp(@x, min.x, max.x)
      @y = Math.clamp(@y, min.y, max.y)
      self
    end

    def clamp_scalar(min, max)
      min, max = min.to_f, max.to_f
      @x = Math.clamp(@x, min, max)
      @y = Math.clamp(@y, min, max)
      self
    end

    def floor
      @x = @x.floor.to_f
      @y = @y.floor.to_f
      self
    end

    def ceil
      @x = @x.ceil.to_f
      @y = @y.ceil.to_f
      self
    end

    def round
      @x = @x.round.to_f
      @y = @y.round.to_f
      self
    end

    def round_to_zero
      @x = ( @x < 0 ) ? @x.ceil.to_f : @x.floor.to_f
      @y = ( @y < 0 ) ? @y.ceil.to_f : @y.floor.to_f
      self
    end

    def negate
      @x = -@x
      @y = -@y
      self
    end

    def dot(v)
      @x * v.x + @y * v.y
    end

    def length
      Math.sqrt(length_sq)
    end

    def length_sq
      self.dot(self)
    end

    def normalize
      self.divide_scalar(self.length)
    end

    def distance_to(v)
      Math.sqrt(distance_to_squared(v))
    end

    def distance_to_squared(v)
      dx, dy = @x - v.x, @y - v.y
      dx * dx + dy * dy
    end

    def length=(l)
      old_length = self.length
      if old_length != 0 && l != old_length
        self.multiply_scalar(l / old_length)
      end
    end

    def lerp(v, alpha)
      @x += (v.x - @x) * alpha
      @y += (v.y - @y) * alpha
      self
    end

    def lerp_vectors(v1, v2, alpha)
      self.sub_vectors(v2, v1).multiply_scalar(alpha).add(v1);
    end

    def ==(v)
      v.x == @x && v.y == @y
    end

    def from_array(array, offset = 0)
      @x = array[offset]
      @y = array[offset + 1]
      self
    end

    def to_array(array = [], offset = 0)
      array.tap { |a|
        a[offset] = @x;
        a[offset + 1] = @y;
      }
    end

    def to_a
      self.to_array
    end

    def from_attribute(attribute, index, offset = 0)
      index = index * attribute.item_size + offset
      @x = attribute.array[index]
      @y = attribute.array[index + 1]
      self
    end

    def clone
      Vector2.new(@x, @y)
    end
  end
end
