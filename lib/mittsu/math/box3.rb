module Mittsu
  class Box3
    attr_accessor :min, :max

    def initialize(min = nil, max = nil)
      @min = min || Mittsu::Vector3.new(Float::INFINITY, Float::INFINITY, Float::INFINITY)
      @max = max || Mittsu::Vector3.new(-Float::INFINITY, -Float::INFINITY, -Float::INFINITY)
    end

    def set(min, max)
      @min.copy(min)
      @max.copy(max)
      self
    end

    def set_from_points(points)
      self.make_empty
      points.each do |point|
        self.expand_by_point(point)
      end
      self
    end

    def set_from_center_and_size(center, size)
      halfSize = size.clone.multiply_scalar(0.5)
      @min.copy(center).sub(halfSize)
      @max.copy(center).add(halfSize)
      self
    end

    def set_from_object(object)
      # Computes the world-axis-aligned bounding box of an object (including its children),
      # accounting for both the object's, and childrens', world transforms
      v1 = Mittsu::Vector3.new
      scope = self
      object.update_matrix_world(true)
      self.make_empty
      object.traverse do |node|
        geometry = node.geometry
        if geometry != nil
          if geometry.is_a?(Mittsu::Geometry)
            vertices = geometry.vertices
            vertices.each do |vertex|
              v1.copy(vertex)
              v1.apply_matrix4(node.matrixWorld)
              scope.expand_by_point(v1)
            end
          elsif geometry.is_a?(Mittsu::BufferGeometry) && geometry.attributes['position'] != nil
            positions = geometry.attributes['position'].array
            positions.each_slice(3) do |postition|
              v1.set(position[0], position[1], position[2])
              v1.apply_matrix4(node.matrixWorld)
              scope.expand_by_point(v1)
            end
          end
        end
      end
      return self
    end

    def copy(box)
      @min.copy(box.min)
      @max.copy(box.max)
      self
    end

    def make_empty
      @min.x = @min.y = @min.z = Float::INFINITY
      @max.x = @max.y = @max.z = -Float::INFINITY
      self
    end

    def empty?
      # self is a more robust check for empty than (volume <= 0) because volume can get positive with two negative axes
      (@max.x < @min.x) || (@max.y < @min.y) || (@max.z < @min.z)
    end

    def center(target = Mittsu::Vector3.new)
      target.add_vectors(@min, @max).multiply_scalar(0.5)
    end

    def size(target = Mittsu::Vector3.new)
      target.sub_vectors(@max, @min)
    end

    def expand_by_point(point)
      @min.min(point)
      @max.max(point)
      self
    end

    def expand_by_vector(vector)
      @min.sub(vector)
      @max.add(vector)
      self
    end

    def expand_by_scalar(scalar)
      @min.add_scalar(-scalar)
      @max.add_scalar(scalar)
      self
    end

    def contains_point?(point)
      !(point.x < @min.x || point.x > @max.x ||
        point.y < @min.y || point.y > @max.y ||
        point.z < @min.z || point.z > @max.z)
    end

    def contains_box?(box)
      ((@min.x <= box.min.x) && (box.max.x <= @max.x) &&
        (@min.y <= box.min.y) && (box.max.y <= @max.y) &&
        (@min.z <= box.min.z) && (box.max.z <= @max.z))
    end

    def parameter(point, target = nil)
      # This can potentially have a divide by zero if the box
      # has a size dimension of 0.
      result = target || Mittsu::Vector3.new
      result.set(
        (point.x - @min.x) / (@max.x - @min.x),
        (point.y - @min.y) / (@max.y - @min.y),
        (point.z - @min.z) / (@max.z - @min.z)
      )
    end

    def intersection_box?(box)
      # using 6 splitting planes to rule out intersections.
      !(box.max.x < @min.x || box.min.x > @max.x ||
        box.max.y < @min.y || box.min.y > @max.y ||
        box.max.z < @min.z || box.min.z > @max.z)
    end

    def clamp_point(point, target = Mittsu::Vector3.new)
      target.copy(point).clamp(@min, @max)
    end

    def distance_to_point(point, target = Mittsu::Vector3.new)
      target.copy(point).clamp(@min, @max).sub(point).length
    end

    def bounding_sphere(target = Mittsu::Sphere.new)
      target.center = self.center
      target.radius = self.size().length * 0.5
      target
    end

    def intersect(box)
      @min.max(box.min)
      @max.min(box.max)
      self
    end

    def union(box)
      @min.min(box.min)
      @max.max(box.max)
      self
    end

    def apply_matrix4(matrix)
      points = [
        # NOTE: I am using a binary pattern to specify all 2^3 combinations below
        Mittsu::Vector3.new(@min.x, @min.y, @min.z).apply_matrix4(matrix), # 000
        Mittsu::Vector3.new(@min.x, @min.y, @max.z).apply_matrix4(matrix), # 001
        Mittsu::Vector3.new(@min.x, @max.y, @min.z).apply_matrix4(matrix), # 010
        Mittsu::Vector3.new(@min.x, @max.y, @max.z).apply_matrix4(matrix), # 011
        Mittsu::Vector3.new(@max.x, @min.y, @min.z).apply_matrix4(matrix), # 100
        Mittsu::Vector3.new(@max.x, @min.y, @max.z).apply_matrix4(matrix), # 101
        Mittsu::Vector3.new(@max.x, @max.y, @min.z).apply_matrix4(matrix), # 110
        Mittsu::Vector3.new(@max.x, @max.y, @max.z).apply_matrix4(matrix)  # 111
      ]
      self.make_empty
      self.set_from_points(points)
      self
    end

    def translate(offset)
      @min.add(offset)
      @max.add(offset)
      self
    end

    def ==(box)
      box.min == @min && box.max == @max
    end

    def clone
      Mittsu::Box3.new.copy(self)
    end

  end
end
