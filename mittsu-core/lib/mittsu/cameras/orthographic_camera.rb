module Mittsu
  class OrthographicCamera < Camera
    attr_accessor :zoom, :left, :right, :top, :bottom, :near, :far

    def initialize(left, right, top, bottom, near = 0.1, far = 2000.0)
      super()

      @type = 'OrthographicCamera'

      @zoom = 1.0

      @left = left.to_f
      @right = right.to_f
      @top = top.to_f
      @bottom = bottom.to_f

      @near = near.to_f
      @far = far.to_f

      update_projection_matrix
    end

    def update_projection_matrix
      dx = (right - left) / (2.0 * zoom)
      dy = (top - bottom) / (2.0 * zoom)
      cx = (right + left) / 2.0
      cy = (top + bottom) / 2.0

      projection_matrix.make_orthographic(cx - dx, cx + dx, cy + dy, cy - dy, near, far)
    end

    def clone
      camera = Mittsu::OrthographicCamera.new
      super(camera)

      camera.zoom = zoom

      camera.left = left
      camera.right = right
      camera.top = top
      camera.bottom = bottom

      camera.near = near
      camera.far = far

      camera.projection_matrix.copy()

      camera
    end

    protected

    def jsonify
      data = super
      data[:left] = self.left
      data[:right] = self.right
      data[:top] = self.top
      data[:bottom] = self.bottom
      data[:near] = self.near
      data[:far] = self.far
      data
    end
  end
end
