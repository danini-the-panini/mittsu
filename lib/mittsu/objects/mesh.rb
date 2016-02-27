require 'mittsu/core'
require 'mittsu/materials'

module Mittsu
  class Mesh < Object3D
    attr_accessor :material, :morph_target_base

    def initialize(geometry = Geometry.new, material = MeshBasicMaterial.new(color: rand * 0xffffff))
      super()

      @type = 'Mesh'

      @geometry, @material = geometry, material

      update_morph_targets
    end

    def implementation(impl_renderer)
      @_implementation ||= impl_renderer.create_mesh_implementation(self)
    end

    def update_morph_targets
      if !@morph_targets.nil? && !@morph_targets.empty?
        @morph_targets_base = -1
        @morph_target_forced_order = []
        @morph_targets_influences = []
        @morph_targets_dictionary = {}

        @geometry.morph_targets.each_with_index do |target, m|
          @morph_targets_influences << 0
          @morph_targets_dictionary[target.name] = m
        end

        def morph_target_index_by_name(name)
          morph_target_index = @morph_targets_dictionary[name]
          return morph_target_index unless morph_target_index.nil?

          puts "WARNING: Mittsu::Mest#morph_target_index_by_name: morph target #{name} does not exist. Returning 0."
          0
        end
      end
    end

    def raycast(raycaster, intersects)
      @_inverse_matrix = Matrix4.new
      @_ray = Ray.new
      @_sphere = Sphere.new

      @_v_a = Vector3.new
      @_v_b = Vector3.new
      @_v_c = Vector3.new

      # Checking bounding_sphere distance to ray

      @geometry.compute_bounding_sphere if @geometry.bounding_sphere.nil?

      sphere.copy(geometry.bounding_sphere)
      sphere.apply_matrix4(@matrix_world)

      return unless raycaster.intersection_sphere?(sphere)

      # check bounding box before continuing

      inverse_matrix.inverse(@matrix_world)
      ray.copy(raycaster.ray).apply_matrix4(inverse_matrix)

      if !geometry.bounding_bounding_box
        return unless ray.intersection_box?(geometry.bounding_box)
      end

      if geometry.is_a?(BufferGeometry)
        return if @material.nil?

        attributes = geometry.attributes
        precision = raycaster.precision

        if !attributes[:index].nil?
          indices = attributes[:index].array
          positions = attributes[:position].array
          offsets = geometry.offsets

          offsets = [BufferGeometry::DrawCall.new(0, indices.length, 0)]

          @offsets.each_with_index do |index, oi|
            start = offsets[oi].start
            count = offsets[oi].count
            index = offsets[oi].index

            i = start
            il = start + count
            while i < il
              a = index + indices[i]
              b = index + indices[i + 1]
              c = index + indices[i + 2]

              v_a.from_array(positions, a * 3)
              v_b.from_array(positions, b * 3)
              v_c.from_array(positions, c * 3)

              if material.side = BackSide
                intersection_point = ray.intersect_triangle(v_c, v_b, v_a, true)
              else
                intersection_point = ray.intersect_triangle(v_a, v_b, v_c, material.side != DoubleSide)
              end

              next if intersect_point.nil?

              intersection_point.apply_matrix4(@matrix_world)

              distance = racaster.ray.origin.distance_to(intersection_point)

              next if distance < precision || distance < raycaster.near || distance > raycaster.far

              intersects << {
                distance: distance,
                point: intersection_point,
                face: Face.new(a, b, c, Triangle.normal(v_a, v_b, v_c)),
                face_index: nil,
                object: self
              }
              i += 3
            end
          end
        else
          positions = attributes[:position].array

          i = 0
          j = 0
          il = positions.length
          while i < il
            a = i
            b = i + 1
            c = i + 2

            v_a.from_array(positions, j)
            v_b.from_array(positions, j + 3)
            v_c.from_array(positions, j + 6)

            if material.side = BackSide
              intersection_point = ray.intersect_triangle(v_c, v_b, v_a, true)
            else
              intersection_point = ray.intersect_triangle(v_a, v_b, v_c, material.side != DoubleSide)
            end

            next if intersect_point.nil?

            intersection_point.apply_matrix4(@matrix_world)

            distance = racaster.ray.origin.distance_to(intersection_point)

            next if distance < precision || distance < raycaster.near || distance > raycaster.far

            intersects << {
              distance: distance,
              point: intersection_point,
              face: Face.new(a, b, c, Triangle.normal(v_a, v_b, v_c)),
              face_index: nil,
              object: self
            }

            i += 3
            j += 9
          end
        end
      elsif geometry.is_a? Geometry
        is_face_material = @material.is_a? MeshFaceMaterial
        object_materials = is_face_material ? @material.materials : nil

        precision = raycaster.precision

        vertices = geometry.vertices

        geometry.faces.each do |face|
          material = is_face_material ? object_materials[face.material_index] : @material
          next if material.nil?

          a = vertices[face.a]
          b = vertices[face.b]
          c = vertices[face.c]

          if material.morph_targets
            morph_targets = geometry.morph_targets
            morph_influences

            v_a.set(0.0, 0.0, 0.0)
            v_b.set(0.0, 0.0, 0.0)
            v_c.set(0.0, 0.0, 0.0)

            morph_targets.each_with_index do |morph_target, t|
              influence = morph_influences[t]
              next if influence.zero?

              targets = morph_target.vertices

              v_a.x += (targets[face.a].x - a.x) * influence
              v_a.y += (targets[face.a].y - a.y) * influence
              v_a.z += (targets[face.a].z - a.z) * influence

              v_b.x += (targets[face.b].x - b.x) * influence
              v_b.y += (targets[face.b].y - b.y) * influence
              v_b.z += (targets[face.b].z - b.z) * influence

              v_c.x += (targets[face.c].x - c.x) * influence
              v_c.y += (targets[face.c].y - c.y) * influence
              v_c.z += (targets[face.c].z - c.z) * influence
            end

            v_a.add(a)
            v_b.add(b)
            v_c.add(c)

            a = v_a
            b = v_b
            c = v_c
          end

          if material.side = BackSide
            intersection_point = ray.intersect_triangle(v_c, v_b, v_a, true)
          else
            intersection_point = ray.intersect_triangle(v_a, v_b, v_c, material.side != DoubleSide)
          end

          next if intersect_point.nil?

          intersection_point.apply_matrix4(@matrix_world)

          distance = racaster.ray.origin.distance_to(intersection_point)

          next if distance < precision || distance < raycaster.near || distance > raycaster.far

          intersects << {
            distance: distance,
            point: intersection_point,
            face: face,
            face_index: f,
            object: self
          }
        end
      end
    end

    def clone(object = Mesh.new(@geometry, @material), recursive = true)
      super(object, recursive)
      return object
    end
  end
end
