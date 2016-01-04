require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '10 OBJ Loader Example'
renderer.shadow_map_enabled = true
renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

loader = Mittsu::OBJMTLLoader.new

object = loader.load('male02.obj', 'male02_dds.mtl')

object.receive_shadow = true
object.cast_shadow = true

object.traverse do |child|
  child.receive_shadow = true
  child.cast_shadow = true
end

scene.add(object)

light = Mittsu::SpotLight.new(0xffffff, 1.0)
light.position.set(300.0, 200.0, 0.0)

light.cast_shadow = true
light.shadow_darkness = 0.5

light.shadow_map_width = 1024
light.shadow_map_height = 1024

light.shadow_camera_near = 1.0
light.shadow_camera_far = 500.0
light.shadow_camera_fov = 60.0

light.shadow_camera_visible = true
scene.add(light)

camera.position.z = 200.0
camera.position.y = 100.0

renderer.window.run do
  object.rotation.y += 0.1
  renderer.render(scene, camera)
end
