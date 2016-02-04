require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
scene.name = 'Root Scene'
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '03 Complex Object Example'

objects = 3.times.map do |i|
  sphere_geometry = Mittsu::SphereGeometry.new(1.0)
  box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
  green_material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
  blue_material = Mittsu::MeshBasicMaterial.new(color: 0x0000ff)
  cube = Mittsu::Mesh.new(box_geometry, green_material)
  cube.name = 'Green Cube'
  sphere = Mittsu::Mesh.new(sphere_geometry, blue_material)
  sphere.name = 'Blue Ball'

  cube.position.set(0.5, 0.0, 0.0)
  sphere.position.set(-0.5, 0.0, 0.0)

  Mittsu::Object3D.new.tap do |o|
    o.add(cube)
    o.add(sphere)
    o.position.x = -3.0 + (i.to_f * 3.0)

    scene.add(o)
  end
end

scene.print_tree

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  objects.each do |object|
    object.rotation.x += 0.1
    object.rotation.y += 0.1
  end

  renderer.render(scene, camera)
end
