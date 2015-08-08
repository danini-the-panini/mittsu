require 'mittsu'

module Mittsu
  class PerspectiveCamera < Camera
    attr_accessor :zoom, :fov, :aspect, :near, :far

    def initialize(fov = 50.0, aspect = 1.0, near = 0.1, far = 2000.0)
      super()

      @type = 'PerspectiveCamera'

      @zoom = 1.0

      @fov = fov.to_f
      @aspect = aspect.to_f
      @near = near.to_f
      @far = far.to_f

      update_projection_matrix
    end

    # Uses Focal Length (in mm) to estimate and set FOV
    # 35mm (fullframe) camera is used if frame size is not specified;
    # Formula based on http://www.bobatkins.com/photography/technical/field_of_view.html
    def set_lens(focal_length, frame_height = 24.0)
      @fov = 2.0 * Math.rad_to_deg(Math.atan(frame_height / (focal_length * 2.0)))
      update_projection_matrix
    end

    # Sets an offset in a larger frustum. This is useful for multi-window or
    # multi-monitor/multi-machine setups.
    #
    # For example, if you have 3x2 monitors and each monitor is 1920x1080 and
    # the monitors are in grid like this
    #
    # +---+---+---+
    # | A | B | C |
    # +---+---+---+
    # | D | E | F |
    # +---+---+---+
    #
    # then for each monitor you would call it like this
    #
    # var w = 1920;
    # var h = 1080;
    # var fullWidth = w * 3;
    # var fullHeight = h * 2;
    #
    # --A--
    # camera.setOffset( fullWidth, fullHeight, w * 0, h * 0, w, h );
    # --B--
    # camera.setOffset( fullWidth, fullHeight, w * 1, h * 0, w, h );
    # --C--
    # camera.setOffset( fullWidth, fullHeight, w * 2, h * 0, w, h );
    # --D--
    # camera.setOffset( fullWidth, fullHeight, w * 0, h * 1, w, h );
    # --E--
    # camera.setOffset( fullWidth, fullHeight, w * 1, h * 1, w, h );
    # --F--
    # camera.setOffset( fullWidth, fullHeight, w * 2, h * 1, w, h );
    #
    # Note there is no reason monitors have to be the same size or in a grid.

    def set_view_offset(full_width, full_height, x, y, width, height)
      @full_width = full_width
      @full_height = full_height
      @x = x
      @y = y
      @width = width
      @height = height

      update_projection_matrix
    end

    def update_projection_matrix
      fov = Math.rad_to_deg(2.0 * Math.atan(Math.tan(Math.deg_to_rad(@fov) * 0.5) / zoom))

      if @full_width
        aspect = @full_width / @full_height
        top = Math.tan(Math.deg_to_rad(fov * 0.5)) * near
        bottom = -top
        left = aspect * bottom
        right = aspect * top
        width = (right - left).abs
        height = (top - bottom).abs

        projection_matrix.make_frustum(
          left + @x * width / @full_width,
          left + (@x + @width) * width / @full_width,
          top - (@y + @height) * height / @full_height,
          top - @y * height / @full_height,
          near,
          far
        )
      else
        projection_matrix.make_perspective(fov, aspect, near, far)
      end
    end

    def clone
      camera = Mittsu::PerspectiveCamera.new
      super(camera)

      camera.zoom = zoom
      camera.fov = fov
      camera.aspect = aspect
      camera.near = near
      camera.far = far

      camera.projection_matrix.copy(projection_matrix)

      camera
    end
  end
end
