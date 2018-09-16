require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '02 Cylinder Mesh Example'

geometry = Mittsu::CylinderGeometry.new(1.0, 1.0, 2.0)
material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00, side: Mittsu::DoubleSide)
ring = Mittsu::Mesh.new(geometry, material)

scene.add(ring)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  ring.rotation.x += 0.1
  ring.rotation.y += 0.1

  renderer.render(scene, camera)
end
