module Mittsu
  class Plane
    attr_accessor :normal, :constant

    def initialize(normal = Mittsu::Vector3.new(1, 0, 0), constant = 0.0)
      @normal, @constant = normal, constant.to_f
    end

    def set(normal, constant)
      @normal.copy(normal)
      @constant = constant.to_f
      self
    end

    def set_components(x, y, z, w)
      @normal.set(x, y, z)
      @constant = w.to_f
      self
    end

    def set_from_normal_and_coplanar_point(normal, point)
      @normal.copy(normal)
      @constant = -point.dot(@normal) # must be @normal, not normal, as @normal is normalized
      self
    end

    def set_from_coplanar_points(a, b, c)
      v1 = Mittsu::Vector3.new
      v2 = Mittsu::Vector3.new
      normal = v1.sub_vectors(c, b).cross(v2.sub_vectors(a, b)).normalize
      # Q: should an error be thrown if normal is zero (e.g. degenerate plane)?
      self.set_from_normal_and_coplanar_point(normal, a)
      self
    end

    def copy(plane)
      @normal.copy(plane.normal)
      @constant = plane.constant
      self
    end

    def normalize
      # Note: will lead to a divide by zero if the plane is invalid.
      inverse_normal_length = 1.0 / @normal.length
      @normal.multiply_scalar(inverse_normal_length)
      @constant *= inverse_normal_length
      self
    end

    def negate
      @constant *= -1.0
      @normal.negate
      self
    end

    def distance_to_point(point)
      @normal.dot(point) + @constant
    end

    def distance_to_sphere(sphere)
      self.distance_to_point(sphere.center) - sphere.radius
    end

    def project_point(point, target = Mittsu::Vector3.new)
      self.ortho_point(point, target).sub(point).negate
    end

    def ortho_point(point, target = Mittsu::Vector3.new)
      perpendicular_magnitude = self.distance_to_point(point)
      target.copy(@normal).multiply_scalar(perpendicular_magnitude)
    end

    def intersection_line?(line)
      # Note: self tests if a line intersects the plane, not whether it (or its end-points) are coplanar with it.
      start_sign = self.distance_to_point(line.start_point)
      end_sign = self.distance_to_point(line.end_point)
      (start_sign < 0 && end_sign > 0) || (end_sign < 0 && start_sign > 0)
    end

    def intersect_line(line, target = Mittsu::Vector3.new)
      v1 = Mittsu::Vector3.new
      direction = line.delta(v1)
      denominator = @normal.dot(direction)
      if denominator.zero?
        # line is coplanar, return origin
        if self.distance_to_point(line.start_point).zero?
          return target.copy(line.start_point)
        end
        # Unsure if this is the correct method to handle this case.
        return nil
      end
      t = -(line.start_point.dot(@normal) + @constant) / denominator
      return nil if t < 0 || t > 1
      target.copy(direction).multiply_scalar(t).add(line.start_point)
    end

    def coplanar_point(target = Mittsu::Vector3.new)
      target.copy(@normal).multiply_scalar(- @constant)
    end

    def apply_matrix4(matrix, normal_matrix = Mittsu::Matrix3.new.normal_matrix(matrix))
      v1 = Mittsu::Vector3.new
      v2 = Mittsu::Vector3.new
      # compute new normal based on theory here:
      # http:#www.songho.ca/opengl/gl_normaltransform.html
      new_normal = v1.copy(@normal).apply_matrix3(normal_matrix)
      new_coplanar_point = self.coplanar_point(v2)
      new_coplanar_point.apply_matrix4(matrix)
      self.set_from_normal_and_coplanar_point(new_normal, new_coplanar_point)
      self
    end

    def translate(offset)
      @constant = @constant - offset.dot(@normal)
      self
    end

    def ==(plane)
      plane.normal == @normal && plane.constant == @constant
    end

    def clone
      Mittsu::Plane.new.copy(self)
    end
  end
end
