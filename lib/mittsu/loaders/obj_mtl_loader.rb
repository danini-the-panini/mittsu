module Mittsu
  class OBJMTLLoader
    include EventDispatcher

    # v float float float
    VERTEX_PATTERN = /v( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

    # vn float float float
    NORMAL_PATTERN = /vn( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

    # vt float flot
    UV_PATTERN = /vt( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

    # f vertex vertex vertex
    FACE_PATTERN1 = /f( +\d+)( +\d+)( +\d+)( +\d+)?/

    # f vertex/uv vertex/uv vertex/uv
    FACE_PATTERN2 = /f( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))?/

    # f vertex/uv/normal vertex/uv/normal vertex/uv/normal ...
    FACE_PATTERN3 = /f( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))?/

    # f vertex//normal vertex//normal vertex//normal ...
    FACE_PATTERN4 = /f( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))?/

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
    end

    def load(url, mtlurl = nil)
      loader = FileLoader.new(@manager)

      text = loader.load(url)
      object = parse(text)

      if !mtlurl.nil?
        mtl_loader = MTLLoader.new(File.dirname(url))
        materials_creator = mtl_loader.load(mtlurl)

        materials_creator.preload

        object.traverse do |child_object|
          if child_object.is_a?(Mesh) && child_object.material.name && !child_object.material.name.empty?
            material = materials_creator.create(child_object.material.name)
            child_object.material = material if material
          end
        end
      end

      object
    end

    def parse(data)
      @face_offset = 0
      @group = Group.new

      @vertices = []
      @normals = []
      @uvs = []

      lines = data.split("\n")

      lines.each do |line|
        line = line.strip

        next if line.empty? || line.start_with?('#')

        case line
        when VERTEX_PATTERN
          # ["v 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
          @vertices << vector($1.to_f, $2.to_f, $3.to_f)
        when NORMAL_PATTERN
          # ["vn 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
          @normals << vector($1.to_f, $2.to_f, $3.to_f)
        when UV_PATTERN
          # ["vt 0.1 0.2", "0.1", "0.2"]
          @uvs << uv($1.to_f, $2.to_f)
        when FACE_PATTERN1
          # ["f 1 2 3", "1", "2", "3", undefined]
          handle_face_line([ $1, $2, $3, $4 ])
        when FACE_PATTERN2
          # ["f 1/1 2/2 3/3", " 1/1", "1", "1", " 2/2", "2", "2", " 3/3", "3", "3", undefined, undefined, undefined]
          handle_face_line(
            [ $2, $5, $8, $11 ], #faces
            [ $3, $6, $9, $12 ] #uv
          )
        when FACE_PATTERN3
          # ["f 1/1/1 2/2/2 3/3/3", " 1/1/1", "1", "1", "1", " 2/2/2", "2", "2", "2", " 3/3/3", "3", "3", "3", undefined, undefined, undefined, undefined]
          handle_face_line(
            [ $2, $6, $10, $14 ], #faces
            [ $3, $7, $11, $15 ], #uv
            [ $4, $8, $12, $16 ] #normal
          )
        when FACE_PATTERN4
          # ["f 1//1 2//2 3//3", " 1//1", "1", "1", " 2//2", "2", "2", " 3//3", "3", "3", undefined, undefined, undefined]
          handle_face_line(
            [ $2, $5, $8, $11 ], #faces
            [ ], #uv
            [ $3, $6, $9, $12 ] #normal
          )
        when /^o /
          new_object(line[2..-1].strip)
          @face_offset = @face_offset + @vertices.length
          @vertices = []
        when /^g /
          # group
          # no use for it in mittsu
        when /^usemtl /
          set_material(line[7..-1].strip)
        when /^mtllib /
          # mtl file

          # TODO: ???
          # if mtllib_callback
          #   mtlfile = line[7..-1].strip
          #   mtllib_callback.(mtlfile)
          # end
        when /^s /
          # Smooth shading
        else
          raise "Mittsu::OBJMTLLoader: Unhandled line #{line}"
        end
      end

      end_object

      @group
    end

    private

    def vector(x, y, z)
      Vector3.new(x, y, z)
    end

    def uv(u, v)
      Vector2.new(u, v)
    end

    def face3(a, b, c, normals = nil)
      Face3.new(a, b, c, normals)
    end

    def new_object(object_name = '')
      end_object
      @object = Object3D.new
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
      new_object if @object.nil?
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

    def handle_quad(faces, uvs, normal_inds)
      if !normal_inds.nil? && !normal_inds.empty?
        add_face(faces[0], faces[1], faces[3], [normal_inds[0], normal_inds[1], normal_inds[3]])
        add_face(faces[1], faces[2], faces[3], [normal_inds[1], normal_inds[2], normal_inds[3]])
      else
        add_face(faces[0], faces[1], faces[3])
        add_face(faces[1], faces[2], faces[3])
      end

      if !uvs.nil? && !uvs.empty?
        add_uvs(uvs[0], uvs[1], uvs[3])
        add_uvs(uvs[1], uvs[2], uvs[3])
      end
    end

    def handle_face_line(faces, uvs = nil, normal_inds = nil)
      new_mesh if @mesh.nil?
      if faces[3].nil?
        handle_triangle(faces, uvs, normal_inds)
      else
        handle_quad(faces, uvs, normal_inds)
      end
    end
  end
end
