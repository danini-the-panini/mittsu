require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '02 Box Mesh Example'

cubes = Mittsu::Group.new
GEOMETRY = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
MATERIAL = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)

def create_cube
  cube = Mittsu::Mesh.new(GEOMETRY, MATERIAL)
  cube.position.x = (rand*2.0-1.0) * 3.0
  cube.position.y = (rand*-2.0+1.0) * 3.0
  cube
end

20.times do
  cubes.add(create_cube)
end

scene.add(cubes)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  cubes.children.each do |cube|
    cube.rotation.x += 0.1
    cube.rotation.y += 0.1
  end

  cubes.remove cubes.children.first
  cubes.add create_cube

  renderer.render(scene, camera)
end
