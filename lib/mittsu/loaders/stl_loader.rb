require 'stringio'

module Mittsu
  class STLLoader
    include EventDispatcher

    FLOAT = /[\d|.|+|\-|e]+/
    NORMAL_PATTERN = /normal\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/
    VERTEX_PATTERN = /^\s*vertex\s+(#{FLOAT})\s+(#{FLOAT})\s+(#{FLOAT})/

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
      @vertex_count = 0
      @line_num = 0
      @_listeners = {}
    end

    def load(url)
      loader = FileLoader.new(@manager)

      text = loader.load(url)
      parse(text)
    end

    def parse(text)
      stream = StringIO.new(text)
      # Load STL header (first 80 bytes max)
      header = stream.gets(80)
      if header.slice(0,5) === "solid"
        stream.rewind
        parse_ascii(stream)
      else
        stream.binmode
        parse_binary(stream)
      end
    end

    private

    def parse_ascii(stream)
      @group = Group.new
      while line = read_line(stream)
        case line
        when /^\s*solid/
          @group.add parse_ascii_solid(stream)
        else
          raise_error
        end
      end
      @group
    end

    def parse_ascii_solid(stream)
      geometry = Geometry.new
      while line = read_line(stream)
        case line
        when /^\s*facet/
          vertices, face = parse_ascii_facet(line, stream)
          geometry.vertices += vertices
          geometry.faces << face
        when /^\s*endsolid/
          break
        else
          raise_error
        end
      end
      geometry.merge_vertices
      geometry.compute_bounding_sphere
      object = Object3D.new
      object.add(Mesh.new(geometry))
      object
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
      @group = Group.new
      geometry = Geometry.new
      num_faces = stream.gets(4).unpack('S<').first
      num_faces.times do |i|
        # Face normal
        normal = read_binary_vector(stream)
        # Vertices
        geometry.vertices << read_binary_vector(stream)
        geometry.vertices << read_binary_vector(stream)
        geometry.vertices << read_binary_vector(stream)
        # Throw away the attribute bytes
        stream.gets(2)
        # Store data
        geometry.faces << Face3.new(@vertex_count, @vertex_count+1, @vertex_count+2, normal)
        @vertex_count += 3
      end
      geometry.merge_vertices
      geometry.compute_bounding_sphere
      object = Object3D.new
      object.add(Mesh.new(geometry))
      @group.add(object)
      @group
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
