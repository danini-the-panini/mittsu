require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '13 Joystick Example'

if !renderer.window.joystick_present?
  puts "ERROR: Please plug in a joystick to run this example."
  exit 1
end

axis_object = Mittsu::Object3D.new
center_cube = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshBasicMaterial.new(color: 0xffffff))
axis_object.add(center_cube)
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

X_AXIS = Mittsu::Vector3.new(1.0, 0.0, 0.0)
Y_AXIS = Mittsu::Vector3.new(0.0, 1.0, 0.0)

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

left_stick = Mittsu::Vector2.new
right_stick = Mittsu::Vector2.new

JOYSTICK_DEADZONE = 0.15
JOYSTICK_SENSITIVITY = 0.1

puts "Joystick Connected: #{renderer.window.joystick_name}"
puts "Number of Axes: #{renderer.window.joystick_axes.count}"
puts "Number of Buttons: #{renderer.window.joystick_buttons.count}"

renderer.window.on_joystick_button_pressed do |joystick, button|
  center_cube.material.color = Mittsu::Color.new(1.0, 0.0, 1.0) if button == 0
end

renderer.window.on_joystick_button_released do |joystick, button|
  center_cube.material.color = Mittsu::Color.new(1.0, 1.0, 1.0) if button == 0
end

renderer.window.run do
  axes = renderer.window.joystick_axes.map do |axis|
    axis.abs < JOYSTICK_DEADZONE ? 0.0 : axis
  end
  left_stick.set(axes[0], axes[1])
  right_stick.set(axes[2], axes[3])

  camera_container.rotate_on_axis(Y_AXIS, left_stick.x * JOYSTICK_SENSITIVITY)
  camera_container.rotate_on_axis(X_AXIS, left_stick.y * JOYSTICK_SENSITIVITY)

  scroll_factor = (1.5 ** (right_stick.y * 0.1))
  camera.zoom *= scroll_factor
  camera.update_projection_matrix

  renderer.render(scene, camera)
end
