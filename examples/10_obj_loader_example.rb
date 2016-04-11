require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '10 OBJ Loader Example'
renderer.shadow_map_enabled = true
renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

loader = Mittsu::OBJMTLLoader.new

object = loader.load(File.expand_path('../male02.obj', __FILE__), 'male02.mtl')

object.receive_shadow = true
object.cast_shadow = true

object.traverse do |child|
  child.receive_shadow = true
  child.cast_shadow = true
end

scene.add(object)

scene.print_tree

floor = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1000.0, 1.0, 1000.0),
  Mittsu::MeshPhongMaterial.new(color: 0xffffff)
)
floor.position.y = -1.0
floor.receive_shadow = true
scene.add(floor)

scene.add Mittsu::AmbientLight.new(0xffffff)

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

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  object.rotation.y += 0.1
  renderer.render(scene, camera)
end
