require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '07 Earth Normal Example'

light = Mittsu::SpotLight.new(0xffffff, 2.0)
light.position.x = 1000
light.look_at(scene.position)
scene.add(light)

geometry = Mittsu::SphereGeometry.new(2.0, 64, 64)
texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './earth.png')
normal = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './earth_normal.png')
material = Mittsu::MeshPhongMaterial.new({ map: texture, normal_map: normal })
earth = Mittsu::Mesh.new(geometry, material)
scene.add(earth)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  earth.rotation.y += 0.01

  renderer.render(scene, camera)
end
