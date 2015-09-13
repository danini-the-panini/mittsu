require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '04 Hemisphere Light Example'

geometry = Mittsu::SphereGeometry.new(1.0)
material = Mittsu::MeshLambertMaterial.new(color: 0xffffff)
cube = Mittsu::Mesh.new(geometry, material)
scene.add(cube)

light = Mittsu::HemisphereLight.new(0xCCF2FF, 0x055E00, 0.5) # blue/green, half intensity
scene.add(light)

camera.position.z = 5.0

renderer.window.run do
  renderer.render(scene, camera)
end
