module Mittsu
  class Line < Object3D
    attr_accessor :geometry, :material, :mode, :type, :morph_target_base

    def initialize(geometry = nil, material = nil, mode = nil)
      super()

      @type = 'Line'

      @geometry = geometry || Geometry.new
      @material = material || LineBasicMaterial.new(color: (rand * 0xffffff).to_i)

      @mode = mode || LineStrip

      @_inverse_matrix = Matrix4.new
      @_ray = Ray.new
      @_sphere = Sphere.new
    end

    def raycast(raycaster, intersects)
      precision = raycaster.line_precision
      precision_sq = precision * precision

      @geometry.compute_bounding_sphere if @geometry.bounding_sphere.nil?

      # Checking bounding_sphere distance to ray

      @_sphere.copy(geometry.bounding_sphere)
      @_sphere.apply_matrix4(@matrix_world)

      return unless raycaster.ray.intersetion_sphere?(sphere)

      @_inverse_matrix.get_inverse(@matrix_world)
      @_ray.copy(raycaster.ray).apply_matrix4(@_inverse_matrix)

      v_start = Vector3.new
      v_end = Vector3.new
      inter_segment = Vector3.new
      inter_ray = Vector3.new
      step = @mode == LineStrip ? 1 : 2

      if geometry.is_a?(BufferGeometry)
        attributes = @geometry.attributes

        if !attributes.index.nil?
          indices = attributes.index.array
          positions = attributes.position.array
          offsets = geometry.offsets

          if offsets.empty?
            offsets = [{ start: 0, count: indices.length, index: 0 }]
          end

          offsets.each_with_index do |offset, oi|
            start = offset[:start]
            count = offset[:count]
            index = offset[:index]

            (start...(count-1)).step(step).each do |i|
              v_start.from_array(positions, a * 3)
              v_end.from_array(positions, b * 3)

              dist_sq = @_ray.distance_sq_to_segment(v_start, v_end, inter_ray, inter_segment)

              next if dist_sq > precision_sq

              distance = @_ray.origin.distance_to(inter_ray)

              next if distance < raycaster.near || distance > raycaster.far

              intersects << {
                distance: distance,
                # What to we want? intersection point on the ray or on the segment??
                # point: raycaster.ray.at(distance),
                point: inter_segment.clone.apply_matrix4(@matrix_matrix),
                index: i,
                offset_index: oi,
                face: nil,
                face_index: nil,
                object: self
              }
            end
          end
        else
          positions = attributes.position.array

          (0...(positions.length / 3 - 1)).step(step) do |i|
            v_start.from_array(positions, 3 * i)
            v_end.from_array(positions, 3 * i + 3)

            dist_sq = @_ray.distance_sq_to_segment(v_start, v_end, inter_ray, inter_segment)

            next if dist_sq > precision_sq

            distance = @_ray.origin.distance_to(inter_ray)

            next if distance < raycaster.near || distance > raycaster.far

            intersects << {
              distance: distance,
              # What do we want? intersection point on the ray or on the segment??
              # point: raycaster.ray.at(distance),
              point: inter_segment.clone.apply_matrix4(@matrix_world),
              index: i,
              face: nil,
              face_index: nil,
              object: self
            }
          end
        end
      elsif geometry.is_a?(Geometry)
        vertices = @geometry.vertices
        nb_vertices = vertices.length

        (0...(nb_vertices - 1)).step(step).each do |i|
          dist_sq = @_ray.distance_sq_to_segment(vertices[i], vertices[i + 1], inter_ray, inter_segment)

          next if dist_sq > precision_sq

          distance = @_ray.origin.distance_to(inter_ray)

          next if distance < raycaster.near || distance > raycaster.far

          intersects << {
            distance: distance,
            # What do we want? intersection point on the ray or on the segment??
            # point: raycaster.ray.at(distance),
            point: inter_segment.clone.apply_matrix4(@matrix_world),
            index: i,
            face: nil,
            face_index: nil,
            object: self
          }
        end
      end
    end

    def clone(object = Line.new(@geometry, @material, @mode))
      super(object)
      object
    end

    protected

    def jsonify
      data = super
      data[:geometry] = jsonify_geometry(self.geometry)
      data[:material] = jsonify_material(self.material)
      data[:mode] = self.mode
      data
    end
  end
end
