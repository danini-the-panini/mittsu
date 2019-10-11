module Mittsu
  class Sphere
    attr_accessor :center, :radius

    def initialize(center = Mittsu::Vector3.new, radius = 0.0)
      @center, @radius = center, radius.to_f
    end

    def set(center, radius)
      @center.copy(center)
      @radius = radius.to_f
      self
    end

    def set_from_points(points, optional_center = nil)
      box = Mittsu::Box3.new
      c = @center
      if optional_center.nil?
        box.set_from_points(points).center(c)
      else
        c.copy(optional_center)
      end
      max_radius_sq = 0.0
      points.each do |point|
        max_radius_sq = [max_radius_sq, c.distance_to_squared(point)].max
      end
      @radius = Math.sqrt(max_radius_sq)
      self
    end

    def copy(sphere)
      @center.copy(sphere.center)
      @radius = sphere.radius
      self
    end

    def empty
      @radius <= 0
    end

    def contains_point?(point)
      point.distance_to_squared(@center) <= @radius * @radius
    end

    def distance_to_point(point)
      point.distance_to(@center) - @radius
    end

    def intersects_sphere?(sphere)
      radiusSum = @radius + sphere.radius
      sphere.center.distance_to_squared(@center) <= radiusSum * radiusSum
    end

    def clamp_point(point, target = Mittsu::Vector3.new)
      delta_length_sq = @center.distance_to_squared(point)
      target.copy(point)
      if delta_length_sq > (@radius * @radius)
        target.sub(@center).normalize
        target.multiply_scalar(@radius).add(@center)
      end
      target
    end

    def bounding_box(target = Mittsu::Box3.new)
      target.set(@center, @center)
      target.expand_by_scalar(@radius)
      target
    end

    def apply_matrix4(matrix)
      @center.apply_matrix4(matrix)
      @radius = @radius * matrix.max_scale_on_axis
      self
    end

    def translate(offset)
      @center.add(offset)
      self
    end

    def ==(sphere)
      sphere.center == (@center) && sphere.radius == @radius
    end

    def clone
      Mittsu::Sphere.new.copy(self)
    end
  end
end
