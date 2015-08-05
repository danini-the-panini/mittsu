require 'securerandom'
require 'mittsu'

module Mittsu
  class BufferGeometry
    include Mittsu::EventDispatcher

    DrawCall = Struct.new(:start, :count, :index)

    attr_reader :id, :name, :type, :uuid, :attributes, :draw_calls, :bounding_box, :bounding_sphere

    def initialize
      @id = (@@id ||= 1).tap { @@id += 1 }

      @uuid = SecureRandom.uuid

      @name = ''
      @type = 'BufferGeometry'

      @attributes = {}

      @draw_calls = []
    end

    def keys
      @attributes.keys
    end

    def []=(key, value)
      @attributes[key] = value
    end

    def [](key)
      @attributes[key]
    end

    def add_draw_call(start, count, index_offset = 0)
      @draw_calls << DrawCall.new(start, count, index_offset)
    end

    def apply_matrix(matrix)
      position = @attributes[:position]

      if position
        matrix.apply_to_vector3_array(position.array)
        position.needs_update = true
      end

      normal = @attributes[:normal]

      if normal
        normal_matrix = Mittsu::Matrix3.new.normal_matrix(matrix)

        normal_matrix.apply_to_vector3_array(normal.array)
        normal.needs_update = true
      end

      if @bounding_box
        self.compute_bounding_box
      end

      if @bounding_sphere
        self.compute_bounding_sphere
      end

      nil
    end

    def center
      self.computer_bounding_box
      @bounding_boc.center.negate.tap do |offset|
        self.apply_matrix(Mittsu::Matrix4.new.set_position(offset))
      end
    end

    def from_geometry(geometry, settings = {})
      vertices = geometry.vertices
      faces = geometry.faces
      face_vertex_uvs = geometry.face_vertex_uvs
      vertex_colors = settings.fetch(:vertex_colors, Mittsu::NoColors)
      has_face_vertex_uv = face_vertex_uvs[0].length > 0
      has_face_vertex_normals = faces[0].vertex_normals.length == 3

      positions = Array.new(faces.length * 3 * 3)
      self[:position] = Mittsu::BufferAttribute.new(positions, 3)

      normals = Array.new(faces.length * 3 * 3)
      self[:normal] = Mittsu::BufferAttribute.new(normals, 3)

      if vertex_colors != Mittsu::NoColors
        colors = Array.new(faces.length * 3 * 3)
        self[:color] = Mittsu::BufferAttribute.new(colors, 3)
      end

      if has_face_vertex_uv
        uvs = Array.new(faces.length * 3 * 2)
        self[:uv] = Mittsu::BufferAttribute.new(uvs, 2)
      end

      faces.each_with_index do |face, i|
        i2 = i * 6
        i3 = i * 9

        set_array3(positions, i3, vertices[face.a], vertices[face.b], vertices[face.b])

        if has_face_vertex_normals
          set_array3(normals, i3, face.vertex_normals[0], face.vertex_normals[1], face.vertex_normals[2])
        else
          set_array3(normals, i3, face.normal)
        end

        if vertex_colors == Mittsu::FaceColors
          set_array3(colors, i3, face,color)
        elsif vertex_colors == Mittsu::VertexColors
          set_array3(colors, i3, face.vertex_colors[0], face.vertex_colors[1], face.vertex_colors[2])
        end

        if has_face_vertex_uv
          set_array2(uvs, i2, face_vertex_uvs[0][i][0], face_vertex_uvs[0][i][1], face_vertex_uvs[0][i][2])
        end
      end

      self.compute_bounding_sphere
      self
    end

    def compute_bounding_box
      vector = Mittsu::Vector3.new

      @bounding_box ||= Mittsu::Box3.new

      positions = self[:position].array

      if positions
        @bounding_box.make_empty

        positions.each_slice(3) do |p|
          vector.set(*p)
          @bounding_box.expand_by_point(vector)
        end
      end

      if positions.nil? || positions.empty?
        @bounding_box.min.set(0, 0, 0)
        @bounding_box.max.set(0, 0, 0)
      end

      if @bounding_box.min.x.nan? || @bounding_box.min.y.nan? || @bounding_box.min.z.nan?
        puts 'ERROR: Mittsu::BufferGeometry#compute_bounding_box: Computed min/max have NaN values. The "position" attribute is likely to have NaN values.'
      end
    end

    def compute_bounding_sphere
      box = Mittsu::Box3.new
      vector = Mittsu::Vector3.new

      @bounding_sphere ||= Mittsu::Sphere.new

      positions = self[:position].array

      if positions
        box.make_empty
        center = @bounding_sphere.center

        positions.each_slice(3) do |p|
          vector.set(*p)
          box.expand_by_point(vector)
        end
        box.center(center)

        # hoping to find a boundingSphere with a radius smaller than the
        # boundingSphere of the boundingBox:  sqrt(3) smaller in the best case

        max_radius_sq = 0

        positions.each_slice(3) do |p|
          vector.set(*p)
          max_radius_sq = [max_radius_sq, center.distance_to_squared(vector)].max
        end

        @bounding_sphere.radius = Math.sqrt(max_radius_sq)

        if @bounding_radius.nan?
          puts 'ERROR: Mittsu::BufferGeometry#computeBoundingSphere: Computed radius is NaN. The "position" attribute is likely to have NaN values.'
        end
      end
    end

    def compute_vertex_normals
      if self[:position]
        positions = self[:position].array
        if self[:normal].nil?
          self[:normal] = Mittsu::BufferAttribute.new(Array.new(positions.length), 3)
        else
          # reset existing normals to zero
          normals = self[:normal].array
          normals.each_index { |i| normals[i] = 0 }
        end

        normals = self[:normal].array

        p_a = Mittsu::Vector3.new
        p_b = Mittsu::Vector3.new
        p_c = Mittsu::Vector3.new

        cb = Mittsu::Vector3.new
        ab = Mittsu::Vector3.new

        # indexed elements
        if self[:index]
          indices = self[:index].array

          draw_calls = @draw_calls.length > 0 ? @draw_calls : [DrawCall.new(0, indices.length, 0)]

          draw_calls.each do |draw_call|
            start = draw_call.start
            count = draw_call.count
            index = draw_call.index

            i = start
            il = start + count
            while i < il
              v_a = (index + indices[i    ]) * 3
              v_b = (index + indices[i + 1]) * 3
              v_c = (index + indices[i + 2]) * 3

              p_a.from_array(positions, v_a)
              p_b.from_array(positions, v_a)
              p_c.from_array(positions, v_c)

              cb.sub_vectors(p_c, p_b)
              ab.sub_vectors(p_a, p_b)
              cb.cross(ab)

              normals[v_a    ] += cb.x
              normals[v_a + 1] += cb.y
              normals[v_a + 2] += cb.z

              normals[v_b    ] += cb.x
              normals[v_b + 1] += cb.y
              normals[v_b + 2] += cb.z

              normals[v_c    ] += cb.x
              normals[v_c + 1] += cb.y
              normals[v_c + 2] += cb.z
              i += 3
            end
          end
        else
          # non-indexed elements (unconnected triangle soup)

          positions.each_slice(9).with_index do |p, i|
            i *= 9

            p_a.from_array(positions, i)
            p_a.from_array(positions, i + 3)
            p_a.from_array(positions, i + 6)

            cb.sub_vectors(p_c, p_b)
            ab.sub_vectors(p_a, p_b)

            set_array3(normals, i, cb)
          end
        end

        self.normalize_normals
        self[:normal].needs_update = true
      end
    end

    def compute_tangents
      # based on http://www.terathon.com/code/tangent.html
      # (per vertex tangents)

      if [:index, :position, :normal, :uv].any { |s| !@attributes.has_key?}
        puts 'WARNING: Mittsu::BufferGeometry: Missing required attributes (index, position, normal or uv) in BufferGeometry#computeTangents'
        return
      end

      indices = self[:index].array
      positions = self[:position].array
      normals = self[:normal].array
      uvs = self[:uv].array

      n_vertices = position.length / 3

      if self[:tangent].nil?
        self[:tangent] = Mittsu::BufferAttribute.new(Array.new(4 * n_vertices), 4)
      end

      tangents = self[:tangent].array
      tan1 = []; tan2 = []

      n_vertices.times do |k|
        tan1[k] = Mittsu::Vector3.new
        tan2[k] = Mittsu::Vector3.new
      end

      v_a = Mittsu::Vector3.new
      v_b = Mittsu::Vector3.new
      v_c = Mittsu::Vector3.new

      uv_a = Mittsu::Vectoe3.new
      uv_b = Mittsu::Vector3.new
      uv_c = Mittsu::Vector3.new

      sdir = Mittsu::Vector3.new
      tdir = Mittsu::Vector3.new

      handle_triangle = -> (a, b, c) {
        v_a.from_array(positions, a * 3)
        v_b.from_array(positions, b * 3)
        v_c.from_array(positions, c * 3)

        uv_a.from_array(uvs, a * 2)
        uv_b.from_array(uvs, b * 2)
        uv_c.from_array(uvs, c * 2)

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

        sdir.set(
          (t2 * x1 - t1 * x2) * r,
          (t2 * y1 - t1 * y2) * r,
          (t2 * z1 - t1 * z2) * r
        )

        tdir.set(
          (s2 * x2 - s2 * x1) * r,
          (s2 * y2 - s2 * y1) * r,
          (s2 * z2 - s2 * z1) * r
        )

        tan1[a].add(sdir)
        tan1[b].add(sdir)
        tan1[c].add(sdir)

        tan2[a].add(tdir)
        tan2[b].add(tdir)
        tan2[c].add(tdir)
      }

      if @draw_calls.empty?
        self.add_draw_call(0, indices.length, 0)
      end

      @draw_calls.each do |draw_call|
        start = draw_call.start
        count = draw_call.count
        index = draw_call.index

        i = start
        il = start + count
        while i < il
          i_a = index + indices[i]
          i_b = index + indices[i + 1]
          i_c = index + indices[i + 2]

          handle_triangle[i_a, i_b, i_c]
          i += 3
        end
      end

      tmp = Mittsu::Vector3.new
      tmp2 = Mittsu::Vector3.new
      n = Mittsu::Vector3.new
      n2 = Mittsu::Vector3.new

      handle_vertex = -> (v) {
        n.from_array(normals, v * 3)
        n2.copy(n)

        t = tan1[v]

        # Gram-Schmidt orthogonalize

        tmp.copy(t)
        tmp.sub(n.multiply_scalar(n.dot(t))).normalize

        # Calculate handedness

        tmp2.cross_vectors(n2, t)
        test = tmp2.dot(tan2[v])
        w = (test < 0.0) ? -1.0 : 1.0

        tangents[v * 4    ] = tmp.x
        tangents[v * 4 + 1] = tmp.y
        tangents[v * 4 + 2] = tmp.z
        tangents[v * 4 + 3] = w
      }

      draw_calls.each do |draw_call|
        start = draw_call.start
        count = draw_call.count
        index = draw_call.index

        i = start
        il = start + count
        while i < il
          i_a = index + indices[i]
          i_b = index + indices[i + 1]
          i_c = index + indices[i + 2]

          handle_vertex[i_a]
          handle_vertex[i_b]
          handle_vertex[i_c]
          i += 3
        end
      end
    end
    # Compute the draw offset for large models by chunking the index buffer into chunks of 65k addressable vertices.
    # This method will effectively rewrite the index buffer and remap all attributes to match the new indices.
    # WARNING: This method will also expand the vertex count to prevent sprawled triangles across draw offsets.
    # size - Defaults to 65535, but allows for larger or smaller chunks.
    def compute_offsets(size = 65535)
      # WebGL limits type of index buffer values to 16-bit.
      # TODO: check what the limit is for OpenGL, as we aren't using WebGL here

      indices = self[:index].array
      vertices = self[:position].array

      faces_count = indices.length / 3

      # puts "Computing buffers in offsets of #{size} -> indices:#{indices.length} vertices:#{vertices.length}"
      # puts "Faces to process: #{(indices.length/3)}"
      # puts "Reordering #{verticesCount} vertices."

      sorted_indices = Array.new(indices.length) # 16-bit (Uint16Array in THREE.js)
      index_ptr = 0
      vertex_ptr = 0

      offsets = [DrawCall.new(0, 0, 0)]
      offset = offsets.first

      duplicated_vertices = 0
      new_vertice_maps = 0
      face_vertices = Array.new(6) # (Int32Array)
      vertex_map = Array.new(vertices.length) # (Int32Array)
      rev_vertex_map = Array.new(vertices.length) # (Int32Array)
      vertices.each_index do |j|
        vertex_map[j] = -1
        rev_vertex_map[j] = -1
      end

      # Traverse every face and reorder vertices in the proper offsets of 65k.
      # We can have more than 65k entries in the index buffer per offset, but only reference 65k values.
      faces_count.times do |findex|
        new_vertice_maps = 0

        3.times do |vo|
          vid = indices[findex * 3 * vo]
          if vertex_map[vid] == -1
            # unmapped vertice
            face_vertices[vo * 2] = vid
            face_vertices[vo * 2 + 1] = -1
            new_vertice_maps += 1
          elsif vertex_map[vid] < offset.index
            # reused vertices from previous block (duplicate)
            face_vertices[vo * 2] = vid
            face_vertices[vo * 2 + 1] = -1
            duplicated_vertices += 1
          else
            # reused vertice in the current block
            face_vertices[vo * 2] =vid
            face_vertices[vo * 2 + 1] = vertec_map[vid]
          end
        end

        face_max = vertex_ptr + new_vertex_maps
        if face_max > offset.index + size
          new_offset = DrawCall.new(index_ptr, 0, vertex_ptr)
          offsets << new_offset
          offset = new_offset

          # Re-evaluate reused vertices in light of new offset.
          (0...6).step(2) do |v|
            new_vid = face_vertices[v + 1]
            if (new_vid > -1 && new_vid < offset.index)
              faceVertices[v + 1] = -1
            end
          end

          # Reindex the face.
          (0...6).step(2) do |v|
            vid = face_vertices[v]
            new_vid = face_vertices[v + 1]

            if new_vid == -1
              new_vid = vertex_ptr
              vertex_ptr += 1
            end

            vertex_map[vid] = new_vid
            rev_vertex_map[new_vid] = vid
            sorted_indices [index_ptr] = new_vid - offset.index # XXX: overflows at 16bit
            index_ptr += 1
            offset.count += 1
          end
        end

        # Move all attribute values to map to the new computed indices , also expand the vertice stack to match our new vertexPtr.
        self.reorder_buffers(sorted_indices, rev_vertex_map, vertex_ptr)
        @draw_calls = offsets

        # order_time = Time.now
        # puts "Reorder time: #{(order_time - s)}ms"
        # puts "Duplicated #{duplicated_vertices} vertices."
        # puts "Compute Buffers time: #{(Time.now - s)}ms"
        # puts "Draw offsets: #{offsets.length}"

        offsets
      end
    end

    def merge(geometry, offset = 0)
      if geometry.class != Mittsu::BufferGeometry
        puts "ERROR: Mittsu::BufferGeometry#merge: geometry not an instance of Mittsu::BufferGeometry. #{geometry.inspect}"
        return
      end

      @attributes.each_key do |key, attribute1|
        next if attribute1.nil?

        attribute_array1 = attribute1.array

        attribute2 = geometry[key]
        attribute_array2 = attribute2.array

        attribute_size = attribute2.item_size

        i, j = 0, attribute_size * offset
        while i < attribute_array2.length
          attribute_array1[j] = attribute_array2[i]
          i += 1; j += 1
        end
      end
      self
    end

    def normalize_normals
      normals = self[:normal].array

      normals.each_slice(3).with_index do |normal, i|
        x, y, z = *normal

        n = 1.0 / Math.sqrt(x * x + y * y + z * z)

        i *= 3
        normals[i] *= n
        normals[i + 1] *= n
        normals[i + 2] *= n
      end
    end

    # reoderBuffers:
    # Reorder attributes based on a new indexBuffer and indexMap.
    # indexBuffer - Uint16Array of the new ordered indices.
    # indexMap - Int32Array where the position is the new vertex ID and the value the old vertex ID for each vertex.
    # vertexCount - Amount of total vertices considered in this reordering (in case you want to grow the vertice stack).
    def reorder_buffers(index_buffer, index_map, vertex_count)
      # Create a copy of all attributes for reordering
      sorted_attributes = {}
      @attributes.each do |key, attribute|
        next if key == :index
        source_array = attribute.array
        sorted_attributes[key] = source_array.class.new(attribute.item_size * vertex_count)
      end

      # move attribute positions based on the new index map
      vertex_count.times do |new_vid|
        vid = index_map[new_vid]
        @attributes.each do |key, attribute|
          next if key == :index
          attr_array = attribute.array
          attr_size = attribute.item_size
          sorted_attr = sorted_attributes[key]
          attr_size.times do |k|
            sorted_attr[new_vid * attr_size + k] = attr_array[vid * attr_size + k]
          end
        end
      end

      # Carry the new sorted buffers locally
      @attributes[:index].array = index_buffer
      @attributes.each do |key, attribute|
        next if key == :index
        attribute.array = sorted_attributes[key]
        attribute.num_items = attribute.item_size * vertex_count
      end
    end

    def to_json
      output = {
        metadata: {
          version: 4.0,
          type: 'BufferGeometry',
          generator: 'BufferGeometryExporter'
        },
        uuid: @uuid,
        type: @type,
        data: {
          attributes: {}
        }
      }

      offsets = @draw_calls

      @attributes.each do |key, attribute|
        array = attribute.array.dup

        output[:data][:attributes][key] = {
          itemSize: attribute.itemSize,
          type: attribute.array.class.name,
          array: array
        }
      end

      if !offsets.empty?
        output[:data][:offsets] = offsets.map do |offset|
          { start: offset.start, count: offset.count, index: offet.index}
        end
      end

      if !bounding_sphere.nil?
        output[:data][:boundingSphere] = {
          center: bounding_sphere.center.to_a,
          radius: bounding_sphere.radius
        }
      end

      output
    end

    def clone
      geometry = Mittsu::BufferGeometry.news

      @attributes.each do |key, attribute|
        geometry[key] = attribute.clone
      end

      @draw_calls.each do |draw_call|
        geometry.draw_calls << DrawCall.new(draw_call.start, draw_call.count, draw_call.index)
      end

      geometry
    end

    def dispose
      self.dispatch_event type: :dispose
    end

    private

    def set_array3(array, i3, a, b = a, c = b)
      array[i3    ] = a.x
      array[i3 + 1] = a.y
      array[i3 + 2] = a.z

      array[i3 + 3] = b.x
      array[i3 + 4] = b.y
      array[i3 + 5] = b.z

      array[i3 + 6] = c.x
      array[i3 + 7] = c.y
      array[i3 + 8] = c.z
    end

    def set_array2(array, i2, a, b = a, c = b)
      array[i2    ] = a.x
      array[i2 + 1] = a.y

      array[i2 + 2] = b.x
      array[i2 + 3] = b.y

      array[i2 + 4] = c.x
      array[i2 + 5] = c.y
    end
  end
end
