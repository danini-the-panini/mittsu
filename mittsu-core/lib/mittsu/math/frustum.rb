module Mittsu
  class Frustum
    attr_accessor :planes

    def initialize(p0 = nil, p1 = nil, p2 = nil, p3 = nil, p4 = nil, p5 = nil)
      @planes = [
        p0 || Mittsu::Plane.new,
        p1 || Mittsu::Plane.new,
        p2 || Mittsu::Plane.new,
        p3 || Mittsu::Plane.new,
        p4 || Mittsu::Plane.new,
        p5 || Mittsu::Plane.new
      ]
    end

    def set(p0, p1, p2, p3, p4, p5)
      planes = self.planes
      planes[0].copy(p0)
      planes[1].copy(p1)
      planes[2].copy(p2)
      planes[3].copy(p3)
      planes[4].copy(p4)
      planes[5].copy(p5)
      self
    end

    def copy(frustum)
      planes = self.planes
      6.times do |i|
        planes[i].copy(frustum.planes[i])
      end
      self
    end

    def set_from_matrix(m)
      planes = self.planes
      me = m.elements
      me0 = me[0]; me1 = me[1]; me2 = me[2]; me3 = me[3]
      me4 = me[4]; me5 = me[5]; me6 = me[6]; me7 = me[7]
      me8 = me[8]; me9 = me[9]; me10 = me[10]; me11 = me[11]
      me12 = me[12]; me13 = me[13]; me14 = me[14]; me15 = me[15]
      planes[0].set_components(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize
      planes[1].set_components(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize
      planes[2].set_components(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize
      planes[3].set_components(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize
      planes[4].set_components(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize
      planes[5].set_components(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize
      self
    end

    def intersects_object?(object)
      sphere = Mittsu::Sphere.new
      geometry = object.geometry
      geometry.compute_bounding_sphere if geometry.bounding_sphere.nil?
      sphere.copy(geometry.bounding_sphere)
      sphere.apply_matrix4(object.matrix_world)
      self.intersects_sphere?(sphere)
    end

    def intersects_sphere?(sphere)
      planes = self.planes
      center = sphere.center
      negRadius = -sphere.radius
      6.times do |i|
        distance = planes[i].distance_to_point(center)
        return false if distance < negRadius
      end
      true
    end

    def intersects_box?(box)
      p1 = Mittsu::Vector3.new
      p2 = Mittsu::Vector3.new
      planes = self.planes
      6.times do |i|
        plane = planes[i]
        p1.x = plane.normal.x > 0 ? box.min.x : box.max.x
        p2.x = plane.normal.x > 0 ? box.max.x : box.min.x
        p1.y = plane.normal.y > 0 ? box.min.y : box.max.y
        p2.y = plane.normal.y > 0 ? box.max.y : box.min.y
        p1.z = plane.normal.z > 0 ? box.min.z : box.max.z
        p2.z = plane.normal.z > 0 ? box.max.z : box.min.z
        d1 = plane.distance_to_point(p1)
        d2 = plane.distance_to_point(p2)
        # if both outside plane, no intersection
        return false if d1 < 0 && d2 < 0
      end
      true
    end

    def contains_point?(point)
      planes = self.planes
      6.times do |i|
        return false if planes[i].distance_to_point(point) < 0
      end
      true
    end

    def clone
      Mittsu::Frustum.new.copy(self)
    end

  end
end
