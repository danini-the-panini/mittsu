require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '04 Point Light Example'

sphere_geometry = Mittsu::SphereGeometry.new(1.0)
box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
green_material = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
blue_material = Mittsu::MeshLambertMaterial.new(color: 0x0000ff)
magenta_material = Mittsu::MeshLambertMaterial.new(color: 0xff00ff)
cube = Mittsu::Mesh.new(box_geometry, green_material)
sphere1 = Mittsu::Mesh.new(sphere_geometry, blue_material)
sphere1.position.set(3.0, 0.0, 0.0)
sphere2 = Mittsu::Mesh.new(sphere_geometry, magenta_material)
sphere2.position.set(-3.0, 0.0, 0.0)

scene.add(cube)
scene.add(sphere1)
scene.add(sphere2)

light = Mittsu::PointLight.new(0xffffff, 0.5, 10.0, 1.5) # white, half intensity
dot = Mittsu::Mesh.new(box_geometry, Mittsu::MeshBasicMaterial.new(color: 0xffffff))
dot.scale.set(0.1, 0.1, 0.1)
light.add(dot)
light.position.set(0.0, 1.5, 0.0)
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
  light_object.rotation.z += 0.1
  cube.rotation.x += 0.1
  cube.rotation.y += 0.1

  renderer.render(scene, camera)
end
