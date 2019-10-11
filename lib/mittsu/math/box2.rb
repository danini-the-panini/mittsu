module Mittsu
  class Box2
    attr_accessor :min, :max

    def initialize(min = nil, max = nil)
      @min = min || Mittsu::Vector2.new(Float::INFINITY, Float::INFINITY)
      @max = max || Mittsu::Vector2.new(-Float::INFINITY, -Float::INFINITY)
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

    def copy(box)
      @min.copy(box.min)
      @max.copy(box.max)
      self
    end

    def make_empty
      @min.x = @min.y = Float::INFINITY
      @max.x = @max.y = - Float::INFINITY
      self
    end

    def empty?
      # this is a more robust check for empty than (volume <= 0) because volume can get positive with two negative axes
      (@max.x < @min.x) || (@max.y < @min.y)
    end

    def center(target = Mittsu::Vector2.new)
      target.add_vectors(@min, @max).multiply_scalar(0.5)
    end

    def size(target = Mittsu::Vector2.new)
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
      !(point.x < @min.x || point.x > @max.x || point.y < @min.y || point.y > @max.y)
    end

    def contains_box?(box)
      ((@min.x <= box.min.x) && (box.max.x <= @max.x) && (@min.y <= box.min.y) && (box.max.y <= @max.y))
    end

    def parameter(point, target = Mittsu::Vector2.new)
      # This can potentially have a divide by zero if the box
      # has a size dimension of 0.
      target.set(
        (point.x - @min.x) / (@max.x - @min.x),
        (point.y - @min.y) / (@max.y - @min.y)
      )
    end

    def intersection_box?(box)
      # using 6 splitting planes to rule out intersections.
      !(box.max.x < @min.x || box.min.x > @max.x || box.max.y < @min.y || box.min.y > @max.y)
    end

    def clamp_point(point, target = nil)
      result = target || Mittsu::Vector2.new
      result.copy(point).clamp(@min, @max)
    end

    def distance_to_point(point)
      clampedPoint = point.clone.clamp(@min, @max)
      clampedPoint.sub(point).length
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

    def translate(offset)
      @min.add(offset)
      @max.add(offset)
      self
    end

    def ==(box)
      box.min == @min && box.max == @max
    end

    def clone
      Mittsu::Box2.new.copy(self)
    end

  end
end
