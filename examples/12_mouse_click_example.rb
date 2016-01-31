require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '12 Mouse Click Example'

camera.position.z = 5.0

cubes = []
renderer.window.on_mouse_button_pressed do |button, position|
  geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
  material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
  cube = Mittsu::Mesh.new(geometry, material)
  cube.position.x = ((position.x/SCREEN_WIDTH)*2.0-1.0) * 5.0
  cube.position.y = ((position.y/SCREEN_HEIGHT)*-2.0+1.0) * 5.0
  scene.add(cube)
  cubes << cube
end

renderer.window.run do
  cubes.each do |cube|
    cube.rotation.x += 0.1
    cube.rotation.y += 0.1
  end

  renderer.render(scene, camera)
end
