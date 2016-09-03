require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '04 Hemisphere Light Example'

geometry = Mittsu::SphereGeometry.new(1.0)

material = Mittsu::MeshLambertMaterial.new(color: 0xff0000)
sphere = Mittsu::Mesh.new(geometry, material)
sphere.position.x = -3.0
scene.add(sphere)

material1 = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
sphere1 = Mittsu::Mesh.new(geometry, material1)
scene.add(sphere1)

material2 = Mittsu::MeshLambertMaterial.new(color: 0x0000ff)
sphere2 = Mittsu::Mesh.new(geometry, material2)
sphere2.position.x = 3.0
scene.add(sphere2)

box_geometry = Mittsu::SphereGeometry.new(1.0)
room_material = Mittsu::MeshPhongMaterial.new(color: 0xffffff)
room_material.side = Mittsu::BackSide
room = Mittsu::Mesh.new(box_geometry, room_material)
room.scale.set(10.0, 10.0, 10.0)
scene.add(room)

light = Mittsu::HemisphereLight.new(0xCCF2FF, 0x055E00, 0.5) # blue/green, half intensity
scene.add(light)

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  renderer.render(scene, camera)
end
