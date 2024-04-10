require 'stringio'

module Mittsu
  class STLLoader
    include EventDispatcher

    FLOAT = /[\d|.|+|\-|e]+/
    NORMAL_PATTERN = /normal\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/
    VERTEX_PATTERN = /^\s*vertex\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
      @_listeners = {}
    end

    def load(url)
      loader = FileLoader.new(@manager)

      data = loader.load(url)
      parse(data)
    end

    def parse(data)
      reset_loader_vars
      stream = StringIO.new(data, "rb")
      # Load STL header (first 80 bytes max)
      header = stream.read(80)
      if header.slice(0,5) === "solid"
        stream.rewind
        parse_ascii(stream)
      else
        parse_binary(stream)
      end
      @group
    end

    private

    def reset_loader_vars
      @vertex_hash = {}
      @vertex_count = 0
      @line_num = 0
      @group = Group.new
    end

    def parse_ascii(stream)
      while line = read_line(stream)
        case line
        when /^\s*solid/
          parse_ascii_solid(stream)
        else
          raise_error
        end
      end
    end

    def parse_ascii_solid(stream)
      vertices = []
      faces = []
      while line = read_line(stream)
        case line
        when /^\s*facet/
          facet_vertices, face = parse_ascii_facet(line, stream)
          vertices += facet_vertices
          faces << face
        when /^\s*endsolid/
          break
        else
          raise_error
        end
      end
      add_mesh vertices, faces
    end

    def parse_ascii_facet(line, stream)
      vertices = []
      normal = nil
      if line.match NORMAL_PATTERN
        normal = Vector3.new($1, $2, $3)
      end
      while line = read_line(stream)
        case line
        when /^\s*outer loop/
          nil # Ignored
        when /^\s*endloop/
          nil # Ignored
        when VERTEX_PATTERN
          vertices << Vector3.new($1, $2, $3)
        when /^\s*endfacet/
          break
        else
          raise_error
        end
      end
      return nil if vertices.length != 3
      # Merge with existing vertices
      face, new_vertices = face_with_merged_vertices(vertices, normal)
      return new_vertices, face
    end

    def parse_binary(stream)
      vertices = []
      faces = []
      num_faces = stream.read(4).unpack('L<').first
      num_faces.times do |i|
        # Face normal
        normal = read_binary_vector(stream)
        # Vertices
        face_vertices = []
        face_vertices << read_binary_vector(stream)
        face_vertices << read_binary_vector(stream)
        face_vertices << read_binary_vector(stream)
        # Throw away the attribute bytes
        stream.read(2)
        # Store data
        face, new_vertices = face_with_merged_vertices(face_vertices, normal)
        faces << face
        vertices += new_vertices
      end
      add_mesh vertices, faces
    end

    def face_with_merged_vertices(vertices, normal)
      new_vertices = []
      indices = []
      vertices.each do |v|
        index, is_new = vertex_index(v)
        indices << index
        new_vertices << v if is_new
      end
      # Return face and new vertex list
      return Face3.new(
        indices[0],
        indices[1],
        indices[2],
        normal
      ), new_vertices
    end

    def vertex_index(vertex)
      key = vertex_key(vertex)
      unless @vertex_hash.has_key? key
        index = @vertex_hash[key] = @vertex_count
        @vertex_count += 1
        return index, true
      else
        return @vertex_hash[key], false
      end
    end

    def vertex_key(vertex)
      vertex.elements.pack("D*")
    end

    def add_mesh(vertices, faces)
      geometry = Geometry.new
      geometry.vertices = vertices
      geometry.faces = faces
      geometry.compute_bounding_sphere
      @group.add Mesh.new(geometry)
    end

    def read_binary_vector(stream)
      Vector3.new(
        read_le_float(stream),
        read_le_float(stream),
        read_le_float(stream)
      )
    end

    def read_le_float(stream)
      stream.read(4).unpack('e').first
    end

    def read_line(stream)
      @line_num += 1
      stream.gets
    end

    def raise_error
      raise "Mittsu::STLLoader: Unhandled line #{@line_num}"
    end
  end
end
