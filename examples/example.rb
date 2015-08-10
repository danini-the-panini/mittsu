require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Example'

# geometry = Mittsu.BoxGeometry.new(1.0, 1.0, 1.0);
# material = Mittsu.MeshBasicMaterial.new(color: 0x00ff00);
# cube = Mittsu.Mesh.new(geometry, material);
# scene.add(cube);

camera.position.z = 5.0

renderer.window.run do
  renderer.render(scene, camera)
end
