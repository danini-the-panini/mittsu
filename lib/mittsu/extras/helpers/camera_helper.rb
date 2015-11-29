require 'mittsu/objects/line'

module Mittsu
  class CameraHelper < Line
    attr_accessor :point_map, :camera, :matrix, :matrix_auto_update, :material, :geometry

    def initialize(camera)
      @_vector = Vector3.new
      @_camera = Camera.new

      @geometry = Geometry.new
      @material = LineBasicMaterial.new(color: 0xffffff, vertex_colors: FaceColors)

      @point_map = {}

      # colors

      @hex_frustrum = 0xffaa00
      @hex_cone = 0xff0000
      @hex_up = 0x00aaff
      @hex_target = 0xffffff
      @hex_cross = 0x333333

      # near

      add_line(:n1, :n2, @hex_frustrum)
      add_line(:n2, :n4, @hex_frustrum)
      add_line(:n4, :n3, @hex_frustrum)
      add_line(:n3, :n1, @hex_frustrum)

      # far

      add_line(:f1, :f2, @hex_frustrum)
      add_line(:f2, :f4, @hex_frustrum)
      add_line(:f4, :f3, @hex_frustrum)
      add_line(:f3, :f1, @hex_frustrum)

      # sides

      add_line(:n1, :f1, @hex_frustrum)
      add_line(:n2, :f2, @hex_frustrum)
      add_line(:n3, :f3, @hex_frustrum)
      add_line(:n4, :f4, @hex_frustrum)

      # cone

      add_line(:p, :n1, @hex_frustrum)
      add_line(:p, :n2, @hex_frustrum)
      add_line(:p, :n3, @hex_frustrum)
      add_line(:p, :n4, @hex_frustrum)

      # up

      add_line(:u1, :u2, @hex_frustrum)
      add_line(:u2, :u3, @hex_frustrum)
      add_line(:u3, :u1, @hex_frustrum)

      # target

      add_line(:c, :t, @hex_frustrum)
      add_line(:p, :c, @hex_frustrum)

      # cross

      add_line(:cn1, :cn2, @hex_frustrum)
      add_line(:cn3, :cn4, @hex_frustrum)

      add_line(:cf1, :cf2, @hex_frustrum)
      add_line(:cf3, :cf4, @hex_frustrum)

      super(@geometry, @material, LinePieces)

      @camera = camera

      @matrix = camera.matrix_world
      @matrix_auto_update = false

      update
    end

    def update
      w = 1.0
      h = 1.0

      # we need just camera projection matrix
      # world matrix must be identity

      @_camera.projection_matrix.copy(@camera.projection_matrix)

      # center / target

      set_point(:c, 0.0, 0.0, -1.0)
      set_point(:t, 0.0, 0.0, 1.0)

      # near

      set_point(:n1, -w, -h, -1.0)
      set_point(:n2,  w, -h, -1.0)
      set_point(:n3, -w,  h, -1.0)
      set_point(:n4,  w,  h, -1.0)

      # far

      set_point(:f1, -w, -h, -1.0)
      set_point(:f2,  w, -h, -1.0)
      set_point(:f3, -w,  h, -1.0)
      set_point(:f4,  w,  h, -1.0)

      # up

      set_point(:u1,  w * 0.7, h * 1.1, -1.0)
      set_point(:u2, -w * 0.7, h * 1.1, -1.0)
      set_point(:u3,      0.0, h * 2.0, -1.0)

      # cross

      set_point(:cf1,  -w, 0.0, 1.0)
      set_point(:cf2,   w, 0.0, 1.0)
      set_point(:cf3, 0.0,  -h, 1.0)
      set_point(:cf4, 0.0,   h, 1.0)

      set_point(:cn1,  -w, 0.0, 1.0)
      set_point(:cn2,   w, 0.0, 1.0)
      set_point(:cn3, 0.0,  -h, 1.0)
      set_point(:cn4, 0.0,   h, 1.0)

      @geometry.vertices_need_update = true
    end

    private

    def add_line(a, b, hex)
      add_point(a, hex)
      add_point(b, hex)
    end

    def add_point(id, hex)
      @geometry.vertices << Vector3.new
      @geometry.colors << Color.new(hex)

      @point_map[id] ||= []
      @point_map[id] << geometry.vertices.length - 1
    end

    def set_point(point, x, y, z)
      @_vector.set(x, y, z).unproject(@_camera)

      points = @point_map[point]

      if !points.nil?
        points.each { |p| @geometry.vertices[p].copy(@_vector) }
      end
    end
  end
end
