require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '03 Complex Object Example'

sphere_geometry = Mittsu::SphereGeometry.new(1.0)
box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
green_material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
blue_material = Mittsu::MeshBasicMaterial.new(color: 0x0000ff)
cube = Mittsu::Mesh.new(box_geometry, green_material)
sphere = Mittsu::Mesh.new(sphere_geometry, blue_material)

cube.position.set(0.5, 0.0, 0.0)
sphere.position.set(-0.5, 0.0, 0.0)

object = Mittsu::Object3D.new
object.add(cube)
object.add(sphere)

scene.add(object)

camera.position.z = 5.0

renderer.window.run do
  object.rotation.x += 0.1
  object.rotation.y += 0.1

  renderer.render(scene, camera)
end
