require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '16 Transparent Objects Example'

geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
material = Mittsu::MeshBasicMaterial.new(color: 0x00ffff, opacity: 0.3, transparent: true)
cube = Mittsu::Mesh.new(geometry, material)
scene.add(cube)

geometry = Mittsu::SphereGeometry.new(1.0)
material = Mittsu::MeshBasicMaterial.new(color: 0xff00ff, opacity: 0.3, transparent: true)
sphere = Mittsu::Mesh.new(geometry, material)
scene.add(sphere)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

t = 0
renderer.window.run do
  cube.rotation.x += 0.1
  cube.rotation.y += 0.1

  sphere.position.set(Math.cos(t)*3.0, 0.0, Math.sin(t)*3.0)

  renderer.render(scene, camera)
  t += 0.1
end
