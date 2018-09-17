require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f
TWO_PI = Math::PI * 2.0

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '02 Parametric Geometry Example'

functions = [
  Mittsu::ParametricGeometry.klein,
  Mittsu::ParametricGeometry.plane(10.0, 10.0),
  Mittsu::ParametricGeometry.mobius,
  Mittsu::ParametricGeometry.mobius3d
]

colors = [
  0x00ff00,
  0xff0000,
  0x0000ff,
  0xff00ff,
  0xffff00,
  0x00ffff
]

meshes = functions.each_with_index.map do |func, i|
  geometry = Mittsu::ParametricGeometry.new(func, 25, 25)
  material = Mittsu::MeshPhongMaterial.new(color: colors[i % colors.length], side: Mittsu::DoubleSide)
  mesh = Mittsu::Mesh.new(geometry, material)
  mesh.scale.set(0.1, 0.1, 0.1)
  mesh.position.x = Math.sin((i.to_f / functions.length.to_f) * TWO_PI) * 2.0
  mesh.position.y = Math.cos((i.to_f / functions.length.to_f) * TWO_PI) * 2.0
  scene.add(mesh)
  mesh
end

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
  meshes.each do |mesh|
    mesh.rotation.x += 0.05
    mesh.rotation.y += 0.05
  end

  renderer.render(scene, camera)
end
