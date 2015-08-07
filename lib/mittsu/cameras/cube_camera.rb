require 'mittsu'

module Mittsu
  class CubeCamera < Object3D
    attr_accessor :render_target

    def initialize(near, far, cube_resolution)
      super

      @type = 'CubeCamera'

      fov = 90.0
      aspect = 1.0

      @camera_px = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_px.up.set(0.0, -1.0, 0.0)
      @camera_px.look_at(Mittsu::Vector3.new(1.0, 0.0, 0.0))
      self.add(@camera_px)

      @camera_nx = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_nx.up.set(0.0, -1.0, 0.0)
      @camera_nx.look_at(Mittsu::Vector3.new(-1.0, 0.0, 0.0))
      self.add(@camera_nx)

      @camera_py = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_py.up.set(0.0, 0.0, 1.0)
      @camera_py.look_at(Mittsu::Vector3.new(0.0, 1.0, 0.0))
      self.add(@camera_py)

      @camera_ny = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_ny.up.set(0.0, 0.0, 1.0)
      @camera_ny.look_at(Mittsu::Vector3.new(0.0, -1.0, 0.0))
      self.add(@camera_ny)

      @camera_pz = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_pz.up.set(0.0, -1.0, 0.0)
      @camera_pz.look_at(Mittsu::Vector3.new(0.0, 0.0, 1.0))
      self.add(@camera_pz)

      @camera_nz = Mittsu::PerspectiveCamera.new(fov, aspect, near, far)
      @camera_nz.up.set(0.0, -1.0, 0.0)
      @camera_nz.look_at(Mittsu::Vector3.new(0.0, 0.0, -1.0))
      self.add(@camera_nz)

      @render_target = Mittsu::OpenGLRenderTargetCube(cube_resolution, cube_resolution, format: Mittsu::RGBFormat, mag_filter: Mittsu::LinearFilter, min_filter: Mittsu::LinearFilter)
    end

    def update_cube_map(renderer, scene)
      generate_mipmaps = render_target.generate_mipmaps

      render_target.generate_mipmaps = false

      render_target.active_cube_face = 0
      renderer.render(scene, @camera_px, render_target)

      render_target.active_cube_face = 1
      renderer.render(scene, @camera_nx, render_target)

      render_target.active_cube_face = 2
      renderer.render(scene, @camera_py, render_target)

      render_target.active_cube_face = 3
      renderer.render(scene, @camera_ny, render_target)

      render_target.active_cube_face = 4
      renderer.render(scene, @camera_pz, render_target)

      render_target.generate_mipmaps = generate_mipmaps

      render_target.active_cube_face = 5
      renderer.render(scene, @camera_nz, render_target)
    end
  end
end
