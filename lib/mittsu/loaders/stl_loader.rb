require 'stringio'

module Mittsu
  class STLLoader
    include EventDispatcher

    FLOAT = /[\d|.|+|\-|e]+/
    NORMAL_PATTERN = /normal\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/
    VERTEX_PATTERN = /^\s*vertex\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
      @group = Group.new
      @vertex_count = 0
      @line_num = 0
      @_listeners = {}
    end

    def load(url)
      loader = FileLoader.new(@manager)

      data = loader.load(url)
      parse(data)
    end

    def parse(data)
      stream = StringIO.new(data)
      # Load STL header (first 80 bytes max)
      header = stream.gets(80)
      if header.slice(0,5) === "solid"
        stream.rewind
        parse_ascii(stream)
      else
        stream.binmode
        parse_binary(stream)
      end
      @group
    end

    private

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
      face = Face3.new(@vertex_count, @vertex_count+1, @vertex_count+2, normal)
      @vertex_count += 3
      return vertices, face
    end

    def parse_binary(stream)
      vertices = []
      faces = []
      num_faces = stream.gets(4).unpack('S<').first
      num_faces.times do |i|
        # Face normal
        normal = read_binary_vector(stream)
        # Vertices
        vertices << read_binary_vector(stream)
        vertices << read_binary_vector(stream)
        vertices << read_binary_vector(stream)
        # Throw away the attribute bytes
        stream.gets(2)
        # Store data
        faces << Face3.new(@vertex_count, @vertex_count+1, @vertex_count+2, normal)
        @vertex_count += 3
      end
      add_mesh vertices, faces
    end

    def add_mesh(vertices, faces)
      geometry = Geometry.new
      geometry.vertices = vertices
      geometry.faces = faces
      geometry.merge_vertices
      geometry.compute_bounding_sphere
      object = Object3D.new
      object.add(Mesh.new(geometry))
      @group.add object
    end

    def read_binary_vector(stream)
      Vector3.new(
        stream.gets(4).unpack('e').first,
        stream.gets(4).unpack('e').first,
        stream.gets(4).unpack('e').first
      )
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
