module Mittsu
  class OBJMTLLoader
    include EventDispatcher

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
    end

    def load(url, mtlurl)
      mtl_loader = MTLLoader.new(File.dirname(url))
      # mtl_loader.cross_origin = @cross_origin # TODO: not needed?
      materials_creator = mtl_loader.load(mtlurl)

      materials_creator.preload

      loader = FileLoader.new(@manager)
      # loader.cross_origin = @cross_origin # TODO: not needed?

      text = loader.load(url)
      object = parse(text)

      object.traverse do |child_object|
        if child_object.is_a?(Mesh) && child_object.material.name && !child_object.material.name.empty?
          material = materials_creator.create(child_object.material.name)
          child_object.material = material if material
        end
      end

      object
    end

    def parse(data)
      @face_offset = 0
      @group = Group.new
      @object = @group

      @geometry = Geometry.new
      @material = MeshLambertMaterial.new
      @mesh = Mesh.new(@geometry, @material)

      @vertices = []
      @normals = []
      @uvs = []

      # v float float float
      vertex_pattern = /v( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

      # vn float float float
      normal_pattern = /vn( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

      # vt float flot
      uv_pattern = /vt( +[\d|.|+|\-|e]+)( +[\d|.|+|\-|e]+)/

      # f vertex vertex vertex
      face_pattern1 = /f( +\d+)( +\d+)( +\d+)?/

      # f vertex/uv vertex/uv vertex/uv
  		face_pattern2 = /f( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))?/

  		# f vertex/uv/normal vertex/uv/normal vertex/uv/normal ...
  		face_pattern3 = /f( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))?/

  		# f vertex//normal vertex//normal vertex//normal ...
  		face_pattern4 = /f( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))?/

      lines = data.split("\n")

      lines.each do |line|
  			line = line.strip

  			next if line.empty? || line.start_with?('#')

  			if vertex_pattern =~ line
  				# ["v 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
  				@vertices << vector($1.to_f, $2.to_f, $3.to_f)
  			elsif normal_pattern =~ line
  				# ["vn 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
  				@normals << vector($1.to_f, $2.to_f, $3.to_f)
  			elsif uv_pattern =~ line
  				# ["vt 0.1 0.2", "0.1", "0.2"]
  				@uvs << uv($1.to_f, $2.to_f)
  			elsif face_pattern1 =~ line
  				# ["f 1 2 3", "1", "2", "3", undefined]
  				handle_face_line([ $1, $2, $3, $4 ])
  			elsif face_pattern2 =~ line
  				# ["f 1/1 2/2 3/3", " 1/1", "1", "1", " 2/2", "2", "2", " 3/3", "3", "3", undefined, undefined, undefined]
  				handle_face_line(
  					[ $2, $5, $8, $11 ], #faces
  					[ $3, $6, $9, $12 ] #uv
  				)
  			elsif face_pattern3 =~ line
  				# ["f 1/1/1 2/2/2 3/3/3", " 1/1/1", "1", "1", "1", " 2/2/2", "2", "2", "2", " 3/3/3", "3", "3", "3", undefined, undefined, undefined, undefined]
  				handle_face_line(
  					[ $2, $6, $10, $14 ], #faces
  					[ $3, $7, $11, $15 ], #uv
  					[ $4, $8, $12, $16 ] #normal
  				)
  			elsif face_pattern4 =~ line
  				# ["f 1//1 2//2 3//3", " 1//1", "1", "1", " 2//2", "2", "2", " 3//3", "3", "3", undefined, undefined, undefined]
  				handle_face_line(
  					[ $2, $5, $8, $11 ], #faces
  					[ ], #uv
  					[ $3, $6, $9, $12 ] #normal
  				)
  			elsif /^o / =~ line
  				# object
  				mesh_n
  				@face_offset = @face_offset + @vertices.length
  				@vertices = []
  				object = Object3D.new
  				object.name = line[2..-1].strip
  				@group.add(object)
  			elsif /^g / =~ line
  				# group
  				mesh_n(line[2..-1].strip, nil)
  			elsif /^usemtl / =~ line
  				# material
  				mesh_n(nil, line[7..-1].strip)
  			elsif /^mtllib / =~ line
  				# mtl file

          # TODO: ???
  				# if mtllib_callback
  				# 	mtlfile = line[7..-1].strip
  				# 	mtllib_callback.(mtlfile)
  				# end
  			elsif /^s / =~ line
  				# Smooth shading
  			else
  				puts "Mittsu::OBJMTLLoader: Unhandled line #{line}"
  			end
      end

      mesh_n(nil, nil)

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

    def mesh_n(mesh_name = nil, material_name = nil)
      if !@vertices.empty?
        @geometry.vertices = @vertices

        @geometry.merge_vertices
        @geometry.compute_face_normals
        @geometry.compute_bounding_sphere

        @object.add(@mesh)

        @geometry = Geometry.new
        @mesh = Mesh.new(@geometry, @material)
      end

      @mesh.name = mesh_name unless mesh_name.nil?

      if !material_name.nil?
        @material = MeshLambertMaterial.new
        @material.name = material_name

        @mesh.material = @material
      end
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

    def handle_face_line(faces, uvs = nil, normal_inds = nil)
      if faces[3].nil?
        add_face(faces[0], faces[1], faces[2], normal_inds)

        if !uvs.nil? && !uvs.empty?
          add_uvs(uvs[0], uvs[1], uvs[2])
        end
      else
        if !normal_inds.nil? && !normal_inds.empty?
          add_face(faces[0], faces[1], fances[3], [normal_inds[0], normal_inds[1], normal_inds[3]])
          add_face(faces[1], faces[2], fances[3], [normal_inds[1], normal_inds[2], normal_inds[3]])
        else
          add_face(faces[0], faces[1], faces[3])
          add_face(faces[1], faces[2], faces[3])
        end

        if !uvs.nil? && !uvs.empty?
          add_uvs(uvs[0], uvs[1], uvs[2])
          add_uvs(uvs[1], uvs[2], uvs[2])
        end
      end
    end
  end
end
