require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '12 Orbit/Zoom Example'

axis_object = Mittsu::Object3D.new
axis_object.add(Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshBasicMaterial.new(color: 0xffffff)))
axis_object.add(Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(10.0, 0.1, 0.1),
  Mittsu::MeshBasicMaterial.new(color: 0xff0000)))
axis_object.add(Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(0.1, 10.0, 0.1),
  Mittsu::MeshBasicMaterial.new(color: 0x00ff00)))
axis_object.add(Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(0.1, 0.1, 10.0),
  Mittsu::MeshBasicMaterial.new(color: 0x0000ff)))
scene.add(axis_object)

camera_container = Mittsu::Object3D.new
camera_container.add(camera)
camera.position.z = 5.0
scene.add(camera_container)

renderer.window.on_scroll do |offset|
  scroll_factor = (1.5 ** (offset.y * 0.1))
  camera.zoom *= scroll_factor
  camera.update_projection_matrix
end

X_AXIS = Mittsu::Vector3.new(1.0, 0.0, 0.0)
Y_AXIS = Mittsu::Vector3.new(0.0, 1.0, 0.0)

mouse_delta = Mittsu::Vector2.new
last_mouse_position = Mittsu::Vector2.new

renderer.window.on_mouse_button_pressed do |button, position|
  if button == GLFW_MOUSE_BUTTON_LEFT
    last_mouse_position.copy(position)
  end
end

renderer.window.on_mouse_move do |position|
  if renderer.window.mouse_button_down?(GLFW_MOUSE_BUTTON_LEFT)
    mouse_delta.copy(last_mouse_position).sub(position)
    last_mouse_position.copy(position)

    camera_container.rotate_on_axis(Y_AXIS, mouse_delta.x * 0.01)
    camera_container.rotate_on_axis(X_AXIS, mouse_delta.y * 0.01)
  end
end

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  renderer.render(scene, camera)
end
