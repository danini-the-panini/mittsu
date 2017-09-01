require 'securerandom'
require 'mittsu'

module Mittsu
  class Geometry
    include EventDispatcher

    MorphNormal = Struct.new(:face_normals, :vertex_normals)
    Normal = Struct.new(:a, :b, :c)

    attr_accessor :name, :vertices, :colors, :faces, :face_vertex_uvs, :morph_targets, :morph_colors, :morph_normals, :skin_weights, :skin_indices, :line_distances, :bounding_box, :bounding_sphere, :has_tangents, :dynamic

    attr_accessor(*%w(vertices morph_targets elements uvs normals tangents colors line_distances groups).map { |s| "#{s}_need_update".to_sym })

    attr_reader :id, :uuid, :type

    def initialize
      super

      @id = (@@id ||= 1).tap { @@id += 1 }

      @name = ''
      @type = 'Geometry'

      @vertices = []
      @colors = [] # one-to-one vertex colors, used in Points and Line

      @faces = []

      @face_vertex_uvs = [[]]

      @morph_targets = []
      @morph_colors = []
      @morph_normals = []

      @skin_weights = []
      @skin_indices = []

      @line_distances = []

      @has_tangents = false

      @vertices_need_update = false
      @morph_targets_need_update = false
      @elements_need_update = false
      @uvs_need_update = false
      @normals_need_update = false
      @tangents_need_update = false
      @colors_need_update = false
      @line_distances_need_update = false
      @groups_need_update = false
    end

    def apply_matrix(matrix)
      normal_matrix = Mittsu::Matrix3.new.get_normal_matrix(matrix)
      @vertices.each do |vertex|
        vertex.apply_matrix4(matrix)
      end
      @faces.each do |face|
        face.normal.apply_matrix3(normal_matrix).normalize
        face.vertex_normals.each do |vertex_normal|
          vertex_normal.apply_matrix3(normal_matrix).normalize
        end
      end
      if @bounding_box
        self.compute_bounding_box
      end
      if @bounding_sphere
        self.compute_bounding_sphere
      end
      @vertices_need_update = true
      @normals_need_update = true
    end

    def from_buffer_geometry(geometry)
      scope = self
      vertices = geometry[:position].array
      indices = geometry[:index].nil? ? nil : geometry[:index].array
      normals = geometry[:normal].nil? ? nil : geometry[:normal].array
      colors = geometry[:color].nil? ? nil : geometry[:color].array
      uvs = geometry[:uv].nil? ? nil : geometry[:uv].array
      temp_normals = []
      temp_uvs = []
      i, j = 0, 0
      while i < vertices.length
        scope.vertices << Mittsu::Vector3.new(vertices[i], vertices[i + 1], vertices[i + 2])
        if normals
          temp_normals << Mittsu::Vector3.new(normals[i], normals[i + 1], normals[i + 2])
        end
        if colors
          scope.colors << Mittsu::Color.new(colors[i], colors[i + 1], colors[i + 2])
        end
        if uvs
          temp_uvs << Mittsu::Vector2.new(uvs[j], uvs[j + 1])
        end
        i += 3; j += 2
      end
      add_face = -> (a, b, c) {
        vertex_normals = normals.nil? ? [] : [temp_normals[a].clone, temp_normals[b].clone, temp_normals[c].clone]
        vertex_colors = colors.nil? ? [] : [scope.colors[a].clone, scope.colors[b].clone, scope.colors[c].clone]
        scope.faces << Mittsu::Face3.new(a, b, c, vertex_normals, vertex_colors)
        if uvs
          scope.face_vertex_uvs[0] << [temp_uvs[a].clone, temp_uvs[b].clone, temp_uvs[c].clone]
        end
      }
      if indices
        draw_calls = geometry.draw_calls
        if !draw_calls.length.empty?
          draw_calls.each do |draw_call|
            start = draw_call.start
            count = draw_call.count
            index = draw_call.index
            j = start
            jl = start + count
            while j < jl
              add_face[index + indices[j], index + indices[j + 1], index + indices[j + 2]]
              j += 3
            end
          end
        else
          indices.each_slice(3).with_index do |index|
            add_face(*index)
          end
        end
      else
        i = 0, il = vertices.length / 3
        while i < il
          add_face[i, i + 1, i + 2]
          i += 3
        end
      end
      self.compute_face_normals
      if geometry.boundingBox
        @bounding_box = geometry.bounding_box.clone
      end
      if geometry.boundingSphere
        @bounding_sphere = geometry.bounding_sphere.clone
      end
      self
    end

    def center
      self.compute_bounding_box
      offset = @bounding_box.center.negate
      self.apply_matrix(Mittsu::Matrix4.new.set_position(offset))
      offset
    end

    def compute_face_normals
      cb, ab = Mittsu::Vector3.new, Mittsu::Vector3.new
      @faces.each do |face|
        v_a = @vertices[face.a]
        v_b = @vertices[face.b]
        v_c = @vertices[face.c]
        cb.sub_vectors(v_c, v_b)
        ab.sub_vectors(v_a, v_b)
        cb.cross(ab)
        cb.normalize
        face.normal.copy(cb)
      end
    end

    def compute_vertex_normals(area_weigted)
      vertices = Array.new(@vertices.length)
      @vertices.length.times do |v|
        vertices[v] = Mittsu::Vector3.new
      end
      if area_weigted
        # vertex normals weighted by triangle areas
        # http:#www.iquilezles.org/www/articles/normals/normals.htm
        cb = Mittsu::Vector3.new, ab = Mittsu::Vector3.new
        @faces.each do |face|
          v_a = @vertices[face.a]
          v_b = @vertices[face.b]
          v_c = @vertices[face.c]
          cb.sub_vectors(v_c, v_b)
          ab.sub_vectors(v_a, v_b)
          cb.cross(ab)
          vertices[face.a].add(cb)
          vertices[face.b].add(cb)
          vertices[face.c].add(cb)
        end
      else
        @faces.each do |face|
          vertices[face.a].add(face.normal)
          vertices[face.b].add(face.normal)
          vertices[face.c].add(face.normal)
        end
      end
      @vertices.each(&:normalize)
      @faces.each do |face|
        face.vertex_normals[0] = vertices[face.a].clone
        face.vertex_normals[1] = vertices[face.b].clone
        face.vertex_normals[2] = vertices[face.c].clone
      end
    end

    def compute_morph_normals
      # save original normals
      # - create temp variables on first access
      #   otherwise just copy (for faster repeated calls)
      @_original_face_normal ||= []
      @_original_vertex_normals ||= []
      @faces.each_with_index do |face, f|
        if !@_original_face_normal[f]
          @_original_face_normal[f] = face.normal.clone
        else
          @_original_face_normal[f].copy(face.normal)
        end
        @_original_vertex_normals[f] ||= []
        face.vertex_normals.each_with_index do |vnorm, i|
          if !@_original_vertex_normals[f][i]
            @_original_vertex_normals[f][i] = vnorm.clone
          else
            @_original_vertex_normals[f][i].copy(face.vertex_normals[i])
          end
        end
      end

      # use temp geometry to compute face and vertex normals for each morph
      tmp_geo = Mittsu::Geometry.new
      tmp_geo.faces = @faces
      @morph_targets.each_with_index do |morph_target, i|
        # create on first access
        if !@morph_normals[i]
          @morph_normals[i] = MorphNormal.new([], [])
          dst_normals_face = @morph_normals[i].face_normals
          dst_normals_vertex = @morph_normals[i].vertex_normals
          @faces.each do
            face_normal = Mittsu::Vector3.new
            vertex_normals = Normal.new(Mittsu::Vector3.new, Mittsu::Vector3.new, Mittsu::Vector3.new)
            dst_normals_face << face_normal
            dst_normals_vertex << vertex_normals
          end
        end
        # set vertices to morph target
        tmp_geo.vertices = @morph_targets[i].vertices
        # compute morph normals
        tmp_geo.compute_face_normals
        tmp_geo.compute_vertex_normals
        # store morph normals
        @faces.each_with_index do |face, f|
          face_normal = @morph_normals[i].face_normals[f]
          vertex_normals = @morph_normals[i].vertex_normals[f]
          face_normal.copy(face.normal)
          vertex_normals.a.copy(face.vertex_normals[0])
          vertex_normals.b.copy(face.vertex_normals[1])
          vertex_normals.c.copy(face.vertex_normals[2])
        end
      end
      # restore original normals
      @faces.each_with_index do |face, f|
        face.normal = @_original_face_normal[f]
        face.vertex_normals = @_original_vertex_normals[f]
      end
    end

    def compute_tangents
      # based on http:#www.terathon.com/code/tangent.html
      # tangents go to vertices
      tan1 = []; tan2 = [],
      sdir = Mittsu::Vector3.new; tdir = Mittsu::Vector3.new
      tmp = Mittsu::Vector3.new; tmp2 = Mittsu::Vector3.new
      n = Mittsu::Vector3.new
      uv = []
      @vertices.each_index do |v|
        tan1[v] = Mittsu::Vector3.new
        tan2[v] = Mittsu::Vector3.new
      end
      handle_triangle = -> (context, a, b, c, ua, ub, uc) {
        v_a = context.vertices[a]
        v_b = context.vertices[b]
        v_c = context.vertices[c]
        uv_a = uv[ua]
        uv_b = uv[ub]
        uv_c = uv[uc]
        x1 = v_b.x - v_a.x
        x2 = v_c.x - v_a.x
        y1 = v_b.y - v_a.y
        y2 = v_c.y - v_a.y
        z1 = v_b.z - v_a.z
        z2 = v_c.z - v_a.z
        s1 = uv_b.x - uv_a.x
        s2 = uv_c.x - uv_a.x
        t1 = uv_b.y - uv_a.y
        t2 = uv_c.y - uv_a.y
        r = 1.0 / (s1 * t2 - s2 * t1)
        sdir.set((t2 * x1 - t1 * x2) * r,
              (t2 * y1 - t1 * y2) * r,
              (t2 * z1 - t1 * z2) * r)
        tdir.set((s1 * x2 - s2 * x1) * r,
              (s1 * y2 - s2 * y1) * r,
              (s1 * z2 - s2 * z1) * r)
        tan1[a].add(sdir)
        tan1[b].add(sdir)
        tan1[c].add(sdir)
        tan2[a].add(tdir)
        tan2[b].add(tdir)
        tan2[c].add(tdir)
      }
      @faces.each_with_index do |face, f|
        uv = @face_vertex_uvs[0][f] # use UV layer 0 for tangents
        handle_triangle[self, face.a, face.b, face.c, 0, 1, 2]
      end
      face_index = ['a', 'b', 'c', 'd']
      @faces.each_with_index do |face, f|
        [face.vertex_normals.length, 3].min.times do |i|
          n.copy(face.vertex_normals[i])
          vertex_index = face[face_index[i]]
          t = tan1[vertex_index]
          # Gram-Schmidt orthogonalize
          tmp.copy(t)
          tmp.sub(n.multiply_scalar(n.dot(t))).normalize
          # Calculate handedness
          tmp2.cross_vectors(face.vertex_normals[i], t)
          test = tmp2.dot(tan2[vertex_index])
          w = (test < 0.0) ? - 1.0 : 1.0
          face.vertex_tangents[i] = Mittsu::Vector4.new(tmp.x, tmp.y, tmp.z, w)
        end
      end
      @has_tangents = true
    end

    def compute_line_distances
      d = 0
      @vertices.each_with_index do |vertex, i|
        if i > 0
          d += vertex.distance_to(@vertices[i - 1])
        end
        @line_distances[i] = d
      end
    end

    def compute_bounding_box
      @bounding_box ||= Mittsu::Box3.new
      @bounding_box.set_from_points(@vertices)
    end

    def compute_bounding_sphere
      @bounding_sphere ||= Mittsu::Sphere.new
      @bounding_sphere.set_from_points(@vertices)
    end

    def merge(geometry, matrix = nil, material_index_offset = nil)
      if !geometry.is_a? Mittsu::Geometry
        puts('ERROR: Mittsu::Geometry#merge: geometry not an instance of Mittsu::Geometry.', geometry.inspect)
        return
      end
      vertexOffset = @vertices.length
      vertices1 = @vertices
      vertices2 = geometry.vertices
      faces1 = @faces
      faces2 = geometry.faces
      uvs1 = @face_vertex_uvs[0]
      uvs2 = geometry.face_vertex_uvs[0]
      material_index_offset ||= 0
      normal_matrix = matrix.nil? ? nil : Mittsu::Matrix3.new.get_normal_matrix(matrix)
      # vertices
      vertices2.each do |vertex|
        vertex_copy = vertex.clone
        vertex_copy.apply_matrix4(matrix) unless matrix.nil?
        vertices1 << vertex_copy
      end
      # faces
      faces2.each do |face|
        face_vertex_normals = face.vertex_normals
        face_vertex_colors = face.vertex_colors
        face_copy = Mittsu::Face3.new(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset)
        face_copy.normal.copy(face.normal)
        if normal_matrix != nil
          face_copy.normal.apply_matrix3(normal_matrix).normalize unless normal_matrix.nil?
        end
        face_vertex_normals.each do |normal|
          normal = normal.clone
          normal.apply_matrix3(normal_matrix).normalize unless normal_matrix.nil?
          face_copy.vertex_normals << normal
        end
        face_copy.color.copy(face.color)
        face_vertex_colors.each do |color|
          face_copy.vertex_colors << color.clone
        end
        face_copy.materialIndex = face.materialIndex + material_index_offset
        faces1 << face_copy
      end
      # uvs
      uvs2.each do |uv|
        continue if uv.nil?
        uv_copy = []
        uv.each do |u|
          uv_copy << u.clone
        end
        uvs1 << uv_copy
      end
    end

    def merge_mesh(mesh)
      if mesh instanceof Mittsu::Mesh == false
        puts('ERROR: Mittsu::Geometry#merge_mesh: mesh not an instance of Mittsu::Mesh.', mesh.inspect)
        return
      end
      mesh.matrix_auto_update && mesh.update_matrix
      self.merge(mesh.geometry, mesh.matrix)
    end

    def merge_vertices
      vertices_map = {} # Hashmap for looking up vertice by position coordinates (and making sure they are unique)
      unique = []; changes = []
      precision_points = 4 # number of decimal points, eg. 4 for epsilon of 0.0001
      precision = 10 ** precision_points
      @vertices.each_with_index do |v, i|
        key = "#{(v.x * precision).round}_#{(v.y * precision).round}_#{(v.z * precision).round}"
        if vertices_map[key].nil?
          vertices_map[key] = i
          unique << v
          changes[i] = unique.length - 1
        else
          #console.log('Duplicate vertex found. ', i, ' could be using ', vertices_map[key])
          changes[i] = changes[vertices_map[key]]
        end
      end
      # if faces are completely degenerate after merging vertices, we
      # have to remove them from the geometry.
      face_indices_to_remove = []
      @faces.each_with_index do |face, i|
        face.a = changes[face.a]
        face.b = changes[face.b]
        face.c = changes[face.c]
        indices = [face.a, face.b, face.c]
        dup_index = -1
        # if any duplicate vertices are found in a Face3
        # we have to remove the face as nothing can be saved
        3.times do |n|
          if indices[n] == indices[(n + 1) % 3]
            dup_index = n
            face_indices_to_remove << i
            break
          end
        end
      end
      face_indices_to_remove.reverse_each do |idx|
        @faces.delete_at idx
        @face_vertex_uvs.each do |uv|
          uv.delete_at idx
        end
      end
      # Use unique set of vertices
      diff = @vertices.length - unique.length
      @vertices = unique
      diff
    end

    def to_json
      output = {
        metadata: {
          version: 4.0,
          type: 'BufferGeometry',
          generator: 'BufferGeometryExporter'
        },
        uuid: self.uuid,
        type: @type
      }
      output.name = @name unless @name.nil? || @name.empty?
      if @parameters
        @parameters.each do |(key, parameter)|
          output[key] = parameter unless parameter.nil?
        end
        return output
      end
      vertices = []
      @vertices.each do |vert|
        vertices << vertex.x << vertex.y << vertex.z
      end
      faces = []
      normals = []
      normals_hash = {}
      colors = []
      colors_hash = {}
      uvs = []
      uvs_hash = {}
      @faces.each_with_index do |face, i|
        has_material = false # face.materialIndex != nil
        has_face_uv = false # deprecated
        has_face_vertex_uv = @face_vertex_uvs[0][i] != nil
        has_face_normal = face.normal.length > 0
        has_face_vertex_normal = face.vertex_normals.length > 0
        has_face_color = face.color.r != 1 || face.color.g != 1 || face.color.b != 1
        has_face_vertex_color = face.vertex_colors.length > 0
        face_type = 0
        face_type = set_bit(face_type, 0, 0)
        face_type = set_bit(face_type, 1, has_material)
        face_type = set_bit(face_type, 2, has_face_uv)
        face_type = set_bit(face_type, 3, has_face_vertex_uv)
        face_type = set_bit(face_type, 4, has_face_normal)
        face_type = set_bit(face_type, 5, has_face_vertex_normal)
        face_type = set_bit(face_type, 6, has_face_color)
        face_type = set_bit(face_type, 7, has_face_vertex_color)
        faces << face_type
        faces << face.a << face.b << face.c
        # if has_material
        #   faces << face.materialIndex
        # end
        if has_face_vertex_uv
          face_vertex_uvs = @face_vertex_uvs[0][i]
          faces << get_uv_index(face_vertex_uvs[0], uvs_hash, uvs)
          faces << get_uv_index(face_vertex_uvs[1], uvs_hash, uvs)
          faces << get_uv_index(face_vertex_uvs[2], uvs_hash, uvs)
        end
        if has_face_normal
          faces << get_normal_index(face.normal)
        end
        if has_face_vertex_normal
          vertex_normals = face.vertex_normals
          faces << get_normal_index(vertex_normals[0], normals_hash, normals)
          faces << get_normal_index(vertex_normals[1], normals_hash, normals)
          faces << get_normal_index(vertex_normals[2], normals_hash, normals)
        end
        if has_face_color
          faces << get_color_index(face.color)
        end
        if has_face_vertex_color
          vertex_colors = face.vertex_colors
          faces << get_color_index(vertex_colors[0], colors_hash, colors)
          faces << get_color_index(vertex_colors[1], colors_hash, colors)
          faces << get_color_index(vertex_colors[2], colors_hash, colors)
        end
      end
      output[:data] = {}
      output[:data][:vertices] = vertices
      output[:data][:normals] = normals
      output[:data][:colors] = colors unless colors.empty?
      output[:data][:uvs] = [uvs] unless uvs.empty? # temporal backward compatibility
      output[:data][:faces] = faces

      #

      output
    end

    def clone
      geometry = Mittsu::Geometry.new
      @vertices.each do |v|
        geometry.vertices << v.clone
      end
      @faces.each do |f|
        geometry.faces << f.clone
      end
      @face_vertex_uvs.each_with_index do |face_vertex_uvs, i|
        geometry.face_vertex_uvs[i] ||= []
        face_vertex_uvs.each do |uvs|
          uvs_copy = []
          uvs.each do |uv|
            uvs_copy << uv.clone
          end
          geometry.face_vertex_uvs[i] << uvs_copy
        end
      end
      geometry
    end

    def dispose
      self.dispatch_event type: :dispose
    end

    private

    def set_bit(value, position, enabled)
      enabled ? value | (1 << position) : value & (~(1 << position))
    end

    def get_normal_index(normal, normals_hash, normals)
      hash = normal.x.to_s + normal.y.to_s + normal.z.to_s
      return normals_hash[hash] unless normals_hash[hash].nil?
      normals_hash[hash] = normals.length / 3
      normals << normal.x << normal.y << normal.z
      normals_hash[hash]
    end

    def get_color_index(color, color_hash, colors)
      hash = color.r.to_s + color.g.to_s + color.b.to_s
      return colors_hash[hash] unless colors_hash[hash].nil?
      colors_hash[hash] = colors.length
      colors << color.get_hex
      colors_hash[hash]
    end

    def get_uv_index(uv, uvs_hash, uvs)
      hash = uv.x.to_s + uv.y.to_s
      return uvs_hash[hash] unless uvs_hash[hash].nil?
      uvs_hash[hash] = uvs.length / 2
      uvs << uv.x << uv.y
      return uvs_hash[hash]
    end
  end
end
