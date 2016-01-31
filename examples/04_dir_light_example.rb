require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '04 Directional Light Example'

geometry = Mittsu::SphereGeometry.new(1.0)
material = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
cube = Mittsu::Mesh.new(geometry, material)
scene.add(cube)

light = Mittsu::DirectionalLight.new(0xffffff, 0.5) # white, half intensity
light.position.set(0.5, 1.0, 0.0)
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
  light_object.rotation.x += 0.1
  light_object.rotation.y += 0.1

  renderer.render(scene, camera)
end
