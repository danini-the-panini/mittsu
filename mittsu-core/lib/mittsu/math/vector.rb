module Mittsu
  class Vector
    attr_accessor :elements, :uv, :index

    def initialize(elements)
      @elements = elements
    end

    def set(elements)
      @elements = elements
      self
    end

    def each_dimension
      self.class::DIMENSIONS.times do |i|
        yield i
      end
    end

    def []=(index, value)
      index = self.class::ELEMENTS[index] if index.is_a?(Symbol)
      raise IndexError if index.nil? || index < 0 || index >= self.class::DIMENSIONS
      @elements[index] = value
    end

    def [](index)
      index = self.class::ELEMENTS[index] if index.is_a?(Symbol)
      raise IndexError if index.nil? || index < 0 || index >= self.class::DIMENSIONS
      @elements[index]
    end

    def copy(v)
      @elements = v.elements.dup
      self
    end

    def add(v)
      each_dimension do |i|
        @elements[i] = @elements[i] + v.elements[i]
      end
      self
    end

    def add_scalar(s)
      @elements.map!{ |e| e + s }
      self
    end

    def add_vectors(a, b)
      each_dimension do |i|
        @elements[i] = a.elements[i] + b.elements[i]
      end
      self
    end

    def sub(v)
      each_dimension do |i|
        @elements[i] = @elements[i] - v.elements[i]
      end
      self
    end

    def sub_scalar(s)
      @elements.map!{ |e| e - s }
      self
    end

    def sub_vectors(a, b)
      each_dimension do |i|
        @elements[i] = a.elements[i] - b.elements[i]
      end
      self
    end

    def multiply(v)
      each_dimension do |i|
        @elements[i] = @elements[i] * v.elements[i]
      end
      self
    end

    def multiply_scalar(s)
      @elements.map!{ |e| e * s }
      self
    end

    def multiply_vectors(a, b)
      each_dimension do |i|
        @elements[i] = a.elements[i] * b.elements[i]
      end
      self
    end

    def divide(v)
      each_dimension do |i|
        @elements[i] = @elements[i] / v.elements[i]
      end
      self
    end

    def divide_scalar(s)
      inv_scalar = s == 0 ? 0 : 1.0 / s
      @elements.map!{ |e| e * inv_scalar }
      self
    end

    def min(v)
      each_dimension do |i|
        @elements[i] = v.elements[i] if @elements[i] > v.elements[i]
      end
      self
    end

    def max(v)
      each_dimension do |i|
        @elements[i] = v.elements[i] if @elements[i] < v.elements[i]
      end
      self
    end

    def clamp(min, max)
      each_dimension do |i|
        @elements[i] = Math.clamp(@elements[i], min.elements[i], max.elements[i])
      end
      self
    end

    def clamp_scalar(min, max)
      @elements.map!{ |e| Math.clamp(e, min, max) }
      self
    end

    def floor
      @elements.map!{ |e| e.floor.to_f }
      self
    end

    def ceil
      @elements.map!{ |e| e.ceil.to_f }
      self
    end

    def round
      @elements.map!{ |e| e.round.to_f }
      self
    end

    def round_to_zero
      @elements.map!{ |e| (e < 0) ? e.ceil.to_f : e.floor.to_f }
      self
    end

    def negate
      @elements.map!{ |e| -e }
      self
    end

    def length_sq
      self.dot(self)
    end

    def length
      ::Math.sqrt(length_sq)
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
      each_dimension do |i|
        @elements[i] += (v.elements[i] - @elements[i]) * alpha
      end
      self
    end

    def lerp_vectors(v1, v2, alpha)
      self.sub_vectors(v2, v1).multiply_scalar(alpha).add(v1)
      self
    end

    def project_on_vector(vector)
      v1 = self.class.new
      v1.copy(vector).normalize
      dot = self.dot(v1)
      self.copy(v1).multiply_scalar(dot)
    end

    def project_on_plane(plane_normal)
      v1 = self.class.new
      v1.copy(self).project_on_vector(plane_normal)
      self.sub(v1)
    end

    def reflect(normal)
      # reflect incident vector off plane orthogonal to normal
      # normal is assumed to have unit length
      v1 = self.class.new
      self.sub(v1.copy(normal).multiply_scalar(2.0 * self.dot(normal)))
    end

    def angle_to(v)
      theta = self.dot(v) / (self.length * v.length)

      # clamp, to handle numerical problems
      ::Math.acos(Math.clamp(theta, -1.0, 1.0))
    end

    def distance_to(v)
      ::Math.sqrt(self.distance_to_squared(v))
    end

    def ==(v)
      each_dimension do |i|
        return false if @elements[i] != v.elements[i]
      end
      true
    end

    def from_array(array, offset = 0)
      each_dimension do |i|
        @elements[i] = array[offset + i]
      end
      self
    end

    def to_array(array = [], offset = 0)
      each_dimension do |i|
        array[offset + i] = @elements[i]
      end
      array
    end
    alias :to_a :to_array

    def clone
      self.class.new(*@elements)
    end

    def to_s
      "[#{@elements.join(', ')}]"
    end
  end
end
