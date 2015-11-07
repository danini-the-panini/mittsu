require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '05 Earth Example'

box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
light = Mittsu::PointLight.new(0xffffff, 4.0, 10.0, 1.5) # white, 4x intensity
dot = Mittsu::Mesh.new(box_geometry, Mittsu::MeshBasicMaterial.new(color: 0xffffff))
dot.scale.set(0.1, 0.1, 0.1)
light.add(dot)
light.position.set(0.0, 1.5, 1.0)
light_object = Mittsu::Object3D.new
light_object.add(light)
scene.add(light_object)

geometry = Mittsu::SphereGeometry.new(1.0, 32, 16)
texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'earth.png')
material = Mittsu::MeshLambertMaterial.new(map: texture)
earth = Mittsu::Mesh.new(geometry, material)
scene.add(earth)

camera.position.z = 5.0

renderer.window.run do
  light_object.rotation.z += 0.05
  earth.rotation.x += 0.05
  earth.rotation.y += 0.05

  renderer.render(scene, camera)
end
