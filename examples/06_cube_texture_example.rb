require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '06 Cube Texture Example'

geometry = Mittsu::SphereGeometry.new(2.0, 32, 16)
texture = Mittsu::ImageUtils.load_texture_cube(
  [ 'rt', 'lf', 'up', 'dn', 'bk', 'ft' ].map { |path|
    File.join File.dirname(__FILE__), 'cubemap', "tron_#{path}.png"
  }
)
material = Mittsu::MeshBasicMaterial.new(env_map: texture)
earth = Mittsu::Mesh.new(geometry, material)
scene.add(earth)

camera.position.z = 5.0
camera_container =  Mittsu::Object3D.new
camera_container.add(camera)
scene.add(camera_container)

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
	camera_container.rotation.y += 0.01;
  renderer.render(scene, camera)
end
