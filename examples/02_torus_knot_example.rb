require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '02 Torus Knot Example'

geometry = Mittsu::TorusKnotGeometry.new(1.0, 0.4, 64, 64)
material = Mittsu::MeshPhongMaterial.new(color: 0x00ff00)
cube = Mittsu::Mesh.new(geometry, material)
scene.add(cube)

geometry2 = Mittsu::TorusGeometry.new(1.0, 0.4, 64, 64)
material2 = Mittsu::MeshPhongMaterial.new(color: 0xff00ff)
cube2 = Mittsu::Mesh.new(geometry2, material2)
# scene.add(cube2)

box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
room_material = Mittsu::MeshPhongMaterial.new(color: 0xffffff)
room_material.side = Mittsu::BackSide
room = Mittsu::Mesh.new(box_geometry, room_material)
room.scale.set(10.0, 10.0, 10.0)
scene.add(room)

light = Mittsu::DirectionalLight.new(0xffffff, 0.5) # white, half intensity
light.position.set(0.6, 0.9, 0.5)
light_object = Mittsu::Object3D.new
light_object.add(light)
scene.add(light_object)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  cube.rotation.x += 0.01
  cube.rotation.y -= 0.01
  cube2.rotation.x += 0.01
  cube2.rotation.y -= 0.01

  renderer.render(scene, camera)
end
