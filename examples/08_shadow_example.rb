require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '08 Shadow Example'
renderer.shadow_map_enabled = true
renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

floor = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(10.0, 1.0, 10.0),
  Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
)
floor.position.y = -1.0
floor.receive_shadow = true
scene.add(floor)

ball = Mittsu::Mesh.new(
  Mittsu::SphereGeometry.new(1.0),
  Mittsu::MeshLambertMaterial.new(color: 0x0000ff)
)
ball.cast_shadow = true
scene.add(ball)

light = Mittsu::SpotLight.new(0xffffff, 0.5)
light.position.set(10.0, 20.0, 0.0)

light.cast_shadow = true
light.shadow_darkness = 0.2

light.shadow_map_width = 1024
light.shadow_map_height = 1024

light.shadow_camera_near = 1.0
light.shadow_camera_far = 100.0
light.shadow_camera_fov = 60.0

light.shadow_camera_visible = true
scene.add(light)

camera.position.z = 5.0
camera.position.y = 5.0
camera.look_at(floor.position)

x = 0
renderer.window.run do
  # break if x > 0
  x += 1
  ball.position.y = Math::sin(x * 0.1)

  renderer.render(scene, camera)
end
