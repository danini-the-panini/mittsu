module Mittsu
  class OBJLoader
    include EventDispatcher

    FLOAT                = /[\d|.|+|\-|e]+/

    VERTEX_PATTERN       = /^v\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/
    NORMAL_PATTERN       = /^vn\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/
    UV_PATTERN           = /^vt\s+(#{FLOAT})\s+(#{FLOAT})/

    FACE_PATTERN         = /^f\s+/
    FACE_V_PATTERN       = /^f\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/
    FACE_V_VT_PATTERN    = /^f\s+(\d+)\/(\d+)\s+(\d+)\/(\d+)\s+(\d+)\/(\d+)(?:\s+(\d+)\/(\d+))?/
    FACE_V_VN_PATTERN    = /^f\s+(\d+)\/\/(\d+)\s+(\d+)\/\/(\d+)\s+(\d+)\/\/(\d+)(?:\s+(\d+)\/\/(\d+))?/
    FACE_V_VT_VN_PATTERN = /^f\s+(\d+)\/(\d+)\/(\d+)\s+(\d+)\/(\d+)\/(\d+)\s+(\d+)\/(\d+)\/(\d+)(?:\s+(\d+)\/(\d+)\/(\d+))?/

    OBJECT_PATTERN       = /^o\s+(.+)$/
    GROUP_PATTERN        = /^g\s+(.+)$/
    SMOOTH_GROUP_PATTERN = /^s\s+(\d|true|false|on|off)$/

    USE_MTL_PATTERN      = /^usemtl\s+(.+)$/
    LOAD_MTL_PATTERN     = /^mtllib\s+(.+)$/

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
      @object = nil
      @mesh = nil
      @material = nil
      @_listeners = {}
    end

    def load(url)
      loader = FileLoader.new(@manager)

      text = loader.load(url)
      parse(text)
    end

    def parse(data)
      init_parsing
      relevant_lines(data).each { |line| parse_line(line) }
      end_object
      @group
    end

    private

    def parse_line(line)
      case line
      when VERTEX_PATTERN       then handle_vertex($1.to_f, $2.to_f, $3.to_f)
      when NORMAL_PATTERN       then handle_normal($1.to_f, $2.to_f, $3.to_f)
      when UV_PATTERN           then handle_uv($1.to_f, $2.to_f)

      when FACE_PATTERN         then parse_face(line)

      when OBJECT_PATTERN       then handle_object($1)
      when GROUP_PATTERN        # ignore
      when SMOOTH_GROUP_PATTERN # ignore

      when USE_MTL_PATTERN      then set_material($1)
      when LOAD_MTL_PATTERN     # TODO
      else                      raise "Mittsu::OBJMTLLoader: Unhandled line #{line}"
      end
    end

    def parse_face(line)
      case line
      when FACE_V_PATTERN       then handle_face(
        [$1, $2, $3, $4])   #face
                            #(uv)
                            #(normal)
      when FACE_V_VT_PATTERN    then handle_face(
        [$1, $3, $5, $7],   #face
        [$2, $4, $6, $8])   #uv
                            #(normal)
      when FACE_V_VN_PATTERN    then handle_face(
        [$1, $3, $5, $7 ],  #face
        [],                 #(uv)
        [$2, $4, $6, $8 ])  #normal
      when FACE_V_VT_VN_PATTERN then handle_face(
        [$1, $4, $7, $10],  #face
        [$2, $5, $8, $11],  #uv
        [$3, $6, $9, $12])  #normal
      end
    end

    def face3(a, b, c, normals = nil)
      Face3.new(a, b, c, normals)
    end

    def init_parsing
      @face_offset = 0
      @group = Group.new
      @vertices = []
      @normals = []
      @uvs = []
    end

    def reset_vertices
      @face_offset = @face_offset + @vertices.length
      @vertices = []
    end

    def relevant_lines(raw_lines)
      raw_lines.split("\n").map(&:strip).reject(&:empty?).reject{|l| l.start_with? '#'}
    end

    def handle_object(object_name = '')
      # Reset if we're already working on a named object
      # otherwise, just name the one we have in progress
      unless @object&.name.nil?
        end_object
        reset_vertices
        @object = nil
      end
      @object ||= Object3D.new
      @object.name = object_name
    end

    def end_object
      return if @object.nil?
      end_mesh
      @group.add(@object)
      @object = nil
    end

    def new_mesh
      end_mesh
      handle_object if @object.nil?
      @geometry = Geometry.new
      @mesh = Mesh.new(@geometry, @material || MeshLambertMaterial.new)
      @mesh.name = @object.name
      @mesh.name += " #{@material.name}" unless @material.nil?
    end

    def end_mesh
      return if @mesh.nil? || @vertices.empty?
      @geometry.vertices = @vertices

      @geometry.merge_vertices
      @geometry.compute_face_normals
      @geometry.compute_bounding_sphere

      @object.add(@mesh)
      @mesh = nil
    end

    def set_material(material_name)
      end_mesh

      @material = MeshLambertMaterial.new
      @material.name = material_name
    end

    def handle_vertex(x, y, z)
      @vertices << Vector3.new(x, y, z)
    end

    def handle_normal(x, y, z)
      @normals << Vector3.new(x, y, z)
    end

    def handle_uv(u, v)
      @uvs << Vector2.new(u, v)
    end

    def add_face(a, b, c, normal_inds = nil)
      if normal_inds.nil?
        @geometry.faces << face3(
          a.to_i - (@face_offset + 1),
          b.to_i - (@face_offset + 1),
          c.to_i - (@face_offset + 1)
        )
      else
        @geometry.faces << face3(
          a.to_i - (@face_offset + 1),
          b.to_i - (@face_offset + 1),
          c.to_i - (@face_offset + 1),
          normal_inds.take(3).map { |i| @normals[i.to_i - 1].clone }
        )
      end
    end

    def add_uvs(a, b, c)
      @geometry.face_vertex_uvs[0] << [
        @uvs[a.to_i - 1].clone,
        @uvs[b.to_i - 1].clone,
        @uvs[c.to_i - 1].clone
      ]
    end

    def handle_triangle(faces, uvs, normal_inds)
      add_face(faces[0], faces[1], faces[2], normal_inds)

      if !uvs.nil? && !uvs.empty?
        add_uvs(uvs[0], uvs[1], uvs[2])
      end
    end

    def handle_face(faces, uvs = [], normal_inds = [])
      new_mesh if @mesh.nil?
      if faces[3].nil?
        handle_triangle(faces, uvs, normal_inds)
      else
        handle_quad(faces, uvs, normal_inds)
      end
    end

    def handle_quad(faces, uvs, normal_inds)
      handle_quad_triangle(faces, uvs, normal_inds, [0, 1, 3])
      handle_quad_triangle(faces, uvs, normal_inds, [1, 2, 3])
    end

    def handle_quad_triangle(faces, uvs, normal_inds, tri_inds)
      handle_triangle(
        faces.values_at(*tri_inds).compact,
        uvs.values_at(*tri_inds).compact,
        normal_inds.values_at(*tri_inds).compact
      )
    end
  end
end
