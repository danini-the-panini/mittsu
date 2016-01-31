require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '05 Earth Example'

light = Mittsu::HemisphereLight.new(0xffffff, 0x000000, 1)
light.position.x = 1000
scene.add(light)

moon_container = Mittsu::Object3D.new

geometry = Mittsu::SphereGeometry.new(1.0, 32, 16)
texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'earth.png')
material = Mittsu::MeshLambertMaterial.new(map: texture)
earth = Mittsu::Mesh.new(geometry, material)
scene.add(earth)

geometry = Mittsu::SphereGeometry.new(0.2725631769, 32, 16)
texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), 'moon.png')
material = Mittsu::MeshLambertMaterial.new(map: texture)
moon = Mittsu::Mesh.new(geometry, material)
moon.position.x = 30.167948517
moon_container.add(moon)

scene.add(moon_container)

camera.position.z = 30.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  moon_container.rotation.y += 0.0003571428571
  earth.rotation.y += 0.01

  renderer.render(scene, camera)
end
