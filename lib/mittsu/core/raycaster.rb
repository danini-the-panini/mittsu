require 'mittsu'

module Mittsu
  class Raycaster
    attr_accessor :near, :far, :ray, :params, :precision

    def initialize(origin = Vector3.new, direction = Vector3.new, near = 0.0, far = Float::INFINITY)
      @ray = Mittsu::Ray.new(origin, direction)
      # direction is assumed to be normalized (for accurate distance calculations)

      @precision = 0.0001
      @line_precision = 1

      @near, @far = near, far

      @params = {
        sprite: {},
        mesh: {},
        point_cloud: { threshold: 1.0 },
        lod:{},
        line: {}
      }
    end

    def set(origin, direction)
      # direction is assumed to be normalized (for accurate distance calculations)
      @ray.set(origin, direction)
    end

    def set_from_camera(coords, camera)
      # camera is assumed _not_ to be a child of a transformed object

      if camera.is_a? Mittsu::PerspectiveCamera
        @ray.origin.copy(camera.position)
        @ray.direction.set(coords.x, coords.y, 0.5).unproject(camera).sub(camera.position).normalize
      elsif camera.is_a? Mittsu::OrthographicCamera
        @ray.origin.set(coords.x, coords.y, -1.0).unproject(camera)
        @ray.direction.set(0.0, 0.0, -1.0).transform_direction(camera.matrix_world)
      else
        puts 'ERROR: Mittsu::Raycaster: Unsupported camera type'
      end
    end

    def intersect_object(object, recursive)
      intersects = []
      intersect(object, intersects, recursive)
      intersects.sort do |a, b|
        a.distance <=> b.distance
      end
    end

    def intersect_objects(objects, recursive = false)
      intersects = []
      if !objects.is_a? Array
        puts 'WARNING: Mittsu::Raycaster#intersect_objects: objects is not an array'
        return intersects
      end

      objects.each do |object|
        intersect(object, intersects, recursive)
      end

      intersects.sort do |a, b|
        a[:distance] <=> b[:distance]
      end
    end

    private

    def intersect(object, intersects, recursive)
      object.raycast(self, intersects)

      object.children.each do |child|
        intersect(chil, intersects, true)
      end
    end
  end
end
