module Mittsu
  class Ray
    attr_accessor :origin, :direction

    def initialize(origin = Mittsu::Vector3.new, direction = Mittsu::Vector3.new)
      @origin, @direction = origin, direction
    end

    def set(origin, direction)
      @origin.copy(origin)
      @direction.copy(direction)
      self
    end

    def copy(ray)
      @origin.copy(ray.origin)
      @direction.copy(ray.direction)
      self
    end

    def at(t, target = Mittsu::Vector3.new)
      target.copy(@direction).multiply_scalar(t).add(@origin)
    end

    def recast(t)
      v1 = Mittsu::Vector3.new
      @origin.copy(self.at(t, v1))
      self
    end

    def closest_point_to_point(point, target = Mittsu::Vector3.new)
      target.sub_vectors(point, @origin)
      direction_distance = target.dot(@direction)
      if direction_distance < 0
        return target.copy(@origin)
      end
      target.copy(@direction).multiply_scalar(direction_distance).add(@origin)
    end

    def distance_to_point(point)
      v1 = Mittsu::Vector3.new
      direction_distance = v1.sub_vectors(point, @origin).dot(@direction)
      # point behind the ray
      if direction_distance < 0
        return @origin.distance_to(point)
      end
      v1.copy(@direction).multiply_scalar(direction_distance).add(@origin)
      v1.distance_to(point)
    end

    def distance_sq_to_segment(v0, v1, point_on_ray = nil, point_on_segment = nil)
      seg_center = Mittsu::Vector3.new
      seg_dir = Mittsu::Vector3.new
      diff = Mittsu::Vector3.new
      # from http:#www.geometrictools.com/LibMathematics/Distance/Wm5DistRay3Segment3.cpp
      # It returns the min distance between the ray and the segment
      # defined by v0 and v1
      # It can also set two optional targets :
      # - The closest point on the ray
      # - The closest point on the segment
      seg_center.copy(v0).add(v1).multiply_scalar(0.5)
      seg_dir.copy(v1).sub(v0).normalize
      diff.copy(@origin).sub(seg_center)
      seg_extent = v0.distance_to(v1) * 0.5
      a01 = -@direction.dot(seg_dir)
      b0 = diff.dot(@direction)
      b1 = -diff.dot(seg_dir)
      c = diff.length_sq
      det = (1.0 - a01 * a01).abs
      if det > 0
        # The ray and segment are not parallel.
        s0 = a01 * b1 - b0
        s1 = a01 * b0 - b1
        ext_det = seg_extent * det
        if s0 >= 0
          if s1 >= -ext_det
            if s1 <= ext_det
              # region 0
              # Minimum at interior points of ray and segment.
              inv_det = 1.0 / det
              s0 *= inv_det
              s1 *= inv_det
              sqr_dist = s0 * (s0 + a01 * s1 + 2.0 * b0) + s1 * (a01 * s0 + s1 + 2.0 * b1) + c
            else
              # region 1
              s1 = seg_extent
              s0 = [0.0, -(a01 * s1 + b0)].max
              sqr_dist = - s0 * s0 + s1 * (s1 + 2.0 * b1) + c
            end
          else
            # region 5
            s1 = - seg_extent
            s0 = [0.0, -(a01 * s1 + b0)].max
            sqr_dist = -s0 * s0 + s1 * (s1 + 2.0 * b1) + c
          end
        else
          if s1 <= - ext_det
            # region 4
            s0 = [0.0, -(-a01 * seg_extent + b0)].max
            s1 = (s0 > 0) ? -seg_extent : [[-seg_extent, -b1].max, seg_extent].min
            sqr_dist = - s0 * s0 + s1 * (s1 + 2 * b1) + c
          elsif s1 <= ext_det
            # region 3
            s0 = 0.0
            s1 = [[-seg_extent, -b1].max, seg_extent].min
            sqr_dist = s1 * (s1 + 2.0 * b1) + c
          else
            # region 2
            s0 = [0.0, -(a01 * seg_extent + b0)].max
            s1 = (s0 > 0) ? seg_extent : [[-seg_extent, -b1].max, seg_extent].min
            sqr_dist = -s0 * s0 + s1 * (s1 + 2.0 * b1) + c
          end
        end
      else
        # Ray and segment are parallel.
        s1 = (a01 > 0) ? -seg_extent : seg_extent
        s0 = [0.0, -(a01 * s1 + b0)].max
        sqr_dist = -s0 * s0 + s1 * (s1 + 2.0 * b1) + c
      end
      if point_on_ray
        point_on_ray.copy(@direction).multiply_scalar(s0).add(@origin)
      end
      if point_on_segment
        point_on_segment.copy(seg_dir).multiply_scalar(s1).add(seg_center)
      end
      sqr_dist
    end

    def intersection_sphere?(sphere)
      self.distance_to_point(sphere.center) <= sphere.radius
    end

    def intersect_sphere(sphere, target = Mittsu::Vector3.new)
      # from http:#www.scratchapixel.com/lessons/3d-basic-lessons/lesson-7-intersecting-simple-shapes/ray-sphere-intersection/
      v1 = Mittsu::Vector3.new
      v1.sub_vectors(sphere.center, @origin)
      tca = v1.dot(@direction)
      d2 = v1.dot(v1) - tca * tca
      radius2 = sphere.radius * sphere.radius
      return nil if d2 > radius2
      thc = Math.sqrt(radius2 - d2)
      # t0 = first intersect point - entrance on front of sphere
      t0 = tca - thc
      # t1 = second intersect point - exit point on back of sphere
      t1 = tca + thc
      # test to see if both t0 and t1 are behind the ray - if so, return nil
      return nil if t0 < 0 && t1 < 0
      # test to see if t0 is behind the ray:
      # if it is, the ray is inside the sphere, so return the second exit point scaled by t1,
      # in order to always return an intersect point that is in front of the ray.
      return self.at(t1, target) if t0 < 0
      # else t0 is in front of the ray, so return the first collision point scaled by t0
      self.at(t0, target)
    end

    def intersection_plane?(plane)
      # check if the ray lies on the plane first
      dist_to_point = plane.distance_to_point(@origin)
      return true if dist_to_point.zero?
      denominator = plane.normal.dot(@direction)
      return true if denominator * dist_to_point < 0
      # ray origin is behind the plane (and is pointing behind it)
      false
    end

    def distance_to_plane(plane)
      denominator = plane.normal.dot(@direction)
      if denominator.zero?
        # line is coplanar, return origin
        return 0.0 if plane.distance_to_point(@origin).zero?
        # Null is preferable to nil since nil means.... it is nil
        return nil
      end
      t = -(@origin.dot(plane.normal) + plane.constant) / denominator
      # Return if the ray never intersects the plane
      t >= 0 ? t : nil
    end

    def intersect_plane(plane, target = Mittsu::Vector3.new)
      t = self.distance_to_plane(plane)
      return nil if t.nil?
      self.at(t, target)
    end

    def intersection_box?(box)
      v = Mittsu::Vector3.new
      !self.intersect_box(box, v).nil?
    end

    def intersect_box(box, target = Mittsu::Vector3.new)
      # http:#www.scratchapixel.com/lessons/3d-basic-lessons/lesson-7-intersecting-simple-shapes/ray-box-intersection/
      invdirx = 1.0 / @direction.x
      invdiry = 1.0 / @direction.y
      invdirz = 1.0 / @direction.z
      origin = @origin
      if invdirx >= 0
        tmin = (box.min.x - origin.x) * invdirx
        tmax = (box.max.x - origin.x) * invdirx
      else
        tmin = (box.max.x - origin.x) * invdirx
        tmax = (box.min.x - origin.x) * invdirx
      end
      if invdiry >= 0
        tymin = (box.min.y - origin.y) * invdiry
        tymax = (box.max.y - origin.y) * invdiry
      else
        tymin = (box.max.y - origin.y) * invdiry
        tymax = (box.min.y - origin.y) * invdiry
      end
      return nil if tmin > tymax || tymin > tmax
      # These lines also handle the case where tmin or tmax is NaN
      # (result of 0 * Infinity). x != x returns true if x is NaN
      tmin = tymin if tymin > tmin || tmin != tmin
      tmax = tymax if tymax < tmax || tmax != tmax
      if invdirz >= 0
        tzmin = (box.min.z - origin.z) * invdirz
        tzmax = (box.max.z - origin.z) * invdirz
      else
        tzmin = (box.max.z - origin.z) * invdirz
        tzmax = (box.min.z - origin.z) * invdirz
      end
      return nil if tmin > tzmax || tzmin > tmax
      tmin = tzmin if tzmin > tmin || tmin != tmin
      tmax = tzmax if tzmax < tmax || tmax != tmax
      #return point closest to the ray (positive side)
      return nil if tmax < 0
      self.at(tmin >= 0 ? tmin : tmax, target)
    end

    def intersect_triangle(a, b, c, backface_culling, target = Mittsu::Vector3.new)
      # Compute the offset origin, edges, and normal.
      diff = Mittsu::Vector3.new
      edge1 = Mittsu::Vector3.new
      edge2 = Mittsu::Vector3.new
      normal = Mittsu::Vector3.new
      # from http:#www.geometrictools.com/LibMathematics/Intersection/Wm5IntrRay3Triangle3.cpp
      edge1.sub_vectors(b, a)
      edge2.sub_vectors(c, a)
      normal.cross_vectors(edge1, edge2)
      # Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
      # E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
      #   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
      #   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
      #   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
      d_dot_n = @direction.dot(normal)
      if d_dot_n > 0
        return nil if backface_culling
        sign = 1.0
      elsif d_dot_n < 0
        sign = -1.0
        d_dot_n = - d_dot_n
      else
        return nil
      end
      diff.sub_vectors(@origin, a)
      d_dot_q_x_e2 = sign * @direction.dot(edge2.cross_vectors(diff, edge2))
      # b1 < 0, no intersection
      return nil if d_dot_q_x_e2 < 0
      d_dot_e1_x_q = sign * @direction.dot(edge1.cross(diff))
      # b2 < 0, no intersection
      return nil if d_dot_e1_x_q < 0
      # b1+b2 > 1, no intersection
      return nil if d_dot_q_x_e2 + d_dot_e1_x_q > d_dot_n
      # Line intersects triangle, check if ray does.
      q_dot_n = -sign * diff.dot(normal)
      # t < 0, no intersection
      return nil if q_dot_n < 0
      # Ray intersects triangle.
      self.at(q_dot_n / d_dot_n, target)
    end

    def apply_matrix4(matrix4)
      @direction.add(@origin).apply_matrix4(matrix4)
      @origin.apply_matrix4(matrix4)
      @direction.sub(@origin)
      @direction.normalize
      self
    end

    def ==(ray)
      ray.origin == @origin && ray.direction == @direction
    end

    def clone
      Mittsu::Ray.new.copy(self)
    end

  end
end
