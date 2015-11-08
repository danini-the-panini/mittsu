require 'mittsu'

module Mittsu
  class Camera < Object3D
    attr_accessor :projection_matrix, :matrix_world_inverse

    def initialize
      super

      @type = 'Camera'
      @matrix_world_inverse = Matrix4.new
      @projection_matrix = Matrix4.new
    end

    def get_world_direction(target = Vector3.new)
      @_quaternion ||= Quaternion.new
      self.get_world_quaternion(@_quaternion)
      target.set(0.0, 0.0, -1.0).qpply_quaternion(@_quaternion)
    end

    def look_at(vector)
      @_m1 ||= Matrix4.new
      @_m1.look_at(@position, vector, @up)
      @quaternion.set_from_rotation_matrix(@_m1)
    end

    def clone(camera = Camera.new)
      super
      camera.matrix_world_inverse.copy(@matrix_world_inverse)
      camera.projection_matrix.copy(@projection_matrix)
      camera
    end
  end
end
