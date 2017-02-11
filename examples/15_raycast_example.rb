require_relative './example_helper'

screen_width = 800
screen_height = 600
ASPECT = screen_width.to_f / screen_height.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: screen_width, height: screen_height, title: '15 Raycast Example'

cursor = Mittsu::Mesh.new(Mittsu::SphereGeometry.new(0.1), Mittsu::MeshBasicMaterial.new(color: 0xff0000))
scene.add(cursor)

cubes = Mittsu::Group.new
5.times { |i| 5.times { |j|
  geometry = Mittsu::BoxGeometry.new(0.5, 0.5, 0.5)
  material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
  cube = Mittsu::Mesh.new(geometry, material)
  cube.position.set(-3.0 + i*1.5, -3.0 + j*1.5, 0.0)
  cube.rotation.set(rand, rand, rand)
  cubes.add(cube)
} }
scene.add(cubes)

camera.position.z = 5.0

mouse_position = Mittsu::Vector2.new

def screen_to_world(vector, camera)
  vector.unproject(camera).sub(camera.position).normalize()
  distance = -camera.position.z / vector.z
  vector.multiply_scalar(distance).add(camera.position)
end

renderer.window.on_mouse_move do |position|
  mouse_position.x = ((position.x/screen_width)*2.0-1.0)
  mouse_position.y = ((position.y/screen_height)*-2.0+1.0)
  screen_to_world(cursor.position.set(mouse_position.x, mouse_position.y, 0.5), camera)
  p cursor.position
end

renderer.window.on_resize do |width, height|
  screen_width, screen_height = width, height
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

raycaster = Mittsu::Raycaster.new

renderer.window.run do
  raycaster.set_from_camera(mouse_position, camera)
  intersects = raycaster.intersect_objects(cubes.children)

  cubes.children.each do |cube|
    cube.material.color.set(0x00ff00)
  end
  intersects.each do |intersect|
    intersect[:object].material.color.set(0xff00ff)
  end

  renderer.render(scene, camera)
end
