require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '08 Shadow Example'

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

light = Mittsu::DirectionalLight.new(0xffffff, 0.5)
light.position.y = 5.0
light.position.x = 5.0
light.position.z = 2.0
light.cast_shadow = true
scene.add(light)

camera.position.z = 5.0
camera.position.y = 5.0
camera.look_at(floor.position)

x = 0
renderer.window.run do
  x += 1
  ball.position.y = Math::sin(x * 0.1)

  renderer.render(scene, camera)
end
