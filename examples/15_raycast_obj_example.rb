require_relative './example_helper'

screen_width = 800
screen_height = 600
ASPECT = screen_width.to_f / screen_height.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: screen_width, height: screen_height, title: '15 Raycast OBJ Example'
renderer.shadow_map_enabled = true
renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

cursor = Mittsu::Mesh.new(Mittsu::SphereGeometry.new(5.0), Mittsu::MeshPhongMaterial.new(color: 0xff00ff))
cursor.receive_shadow = true
cursor.cast_shadow = true
scene.add(cursor)

loader = Mittsu::OBJMTLLoader.new

object = loader.load(File.expand_path('../male02.obj', __FILE__), 'male02.mtl')

object.receive_shadow = true
object.cast_shadow = true

object.traverse do |child|
  child.receive_shadow = true
  child.cast_shadow = true
end

scene.add(object)

floor = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1000.0, 1.0, 1000.0),
  Mittsu::MeshPhongMaterial.new(color: 0xffffff)
)
floor.position.y = -1.0
floor.receive_shadow = true
scene.add(floor)

scene.add Mittsu::AmbientLight.new(0x999999)

light = Mittsu::SpotLight.new(0xffffff, 1.0)
light.position.set(300.0, 200.0, 0.0)

light.cast_shadow = true
light.shadow_darkness = 0.5

light.shadow_map_width = 1024
light.shadow_map_height = 1024

light.shadow_camera_near = 1.0
light.shadow_camera_far = 2000.0
light.shadow_camera_fov = 60.0

light.shadow_camera_visible = false
scene.add(light)

camera.position.z = 200.0
camera.position.y = 100.0

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
  intersects = raycaster.intersect_object(object, true)

  if intersects.empty?
    cursor.visible = false
  else
    cursor.visible = true
    cursor.position.copy(intersects.first[:point])
  end

  object.rotation.y += 0.1
  renderer.render(scene, camera)
end
