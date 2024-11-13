module Mittsu
  class PointCloud < Object3D
    attr_accessor :geometry, :material

    def initialize(geometry = Geometry.new, material = PointCloudMaterial.new(color: rand * 0xffffff))
      super()

      @type = 'PointCloud'

      @geometry = geometry
      @material = material

      @_inverse_matrix = Matrix4.new
      @_ray = Ray.new
    end

    def raycast(raycaster, intersects)
      threshold = raycaster.params[:point_cloud][:threshold]
      @_inverse_matrix.inverse(self.matrix_world)
      @_ray.copy(raycaster.ray).apply_matrix4(@_inverse_matrix)

      if !geometry.bounding_box.nil?
        return if @_ray.intersection_box?(geometry.bounding_box) == false
      end

      local_threshold = threshold / ((self.scale.x + self.scale.y + self.scale.z) / 3.0)
      position = Vector3.new

      if geometry.is_a?(BufferGeometry)
        attributes = geometry.attributes
        positions = attributes.position.array

        if !attributes[:index].nil?
          indices = attributes[:index][:array]
          offsets = geometry.compute_offsets

          if offsets.empty?
            offsets = [{
              start: 0,
              count: indices.length,
              index: 0
            }]
          end

          offsets.each do |offset|
            start = offset[:start]
            count = offset[:count]
            index = offset[:index]

            (start...start+count).each do |i|
              a = index + indices[i]
              position.from_array(positions, a * 3)
              test_point(position, a, local_threshold, raycaster, intersects)
            end
          end
        else
          point_count = positions.count / 3

          point_count.times do |i|
            position.set(
              positions[3 * i],
              positions[3 * i + 1],
              positions[3 * i + 2]
            )

            test_point(position, i, local_threshold, raycaster, intersects)
          end
        end
      else
        geometry.vertices.each_with_index do |vertex, i|
          test_point(vertex, i, local_threshold, raycaster, intersects)
        end
      end
    end

    def clone(object = PointCloud.new(@geometry, @material))
      super(object)
    end

    private

    def test_point(point, index, local_threshold, raycaster, intersects)
      ray_point_distance = @_ray.distance_to_point(point)
      if ray_point_distance < local_threshold
        intersect_point = @_ray.closest_point_to_point(point)
        intersect_point.apply_matrix4(self.matrix_world)

        distance = raycaster.ray.origin.distance_to(intersect_point)
        intersects << {
          distance: distance,
          distance_to_ray: ray_point_distance,
          point: intersect_point.clone,
          index: index,
          face: nil,
          object: self
        }
      end
    end
  end
end
