require 'stringio'

module Mittsu
  class STLLoader
    include EventDispatcher

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
      parse_ascii(stream)
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
      if line.match /([\d\.]+) ([\d\.]+) ([\d\.]+)/
        normal = Vector3.new($1, $2, $3)
      end
      while line = read_line(stream)
        case line
        when /^\s*outer loop/
          nil # Ignored
        when /^\s*endloop/
          nil # Ignored
        when /^\s*vertex ([\d\.]+) ([\d\.]+) ([\d\.]+)/
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

    def read_line(stream)
      @line_num += 1
      stream.gets
    end

    def raise_error
      raise "Mittsu::STLLoader: Unhandled line #{@line_num}"
    end
  end
end
