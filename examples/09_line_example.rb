require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '09 Line Example'

ball = Mittsu::Mesh.new(
  Mittsu::SphereGeometry.new(0.1),
  Mittsu::MeshBasicMaterial.new(color: 0xff00ff)
)
scene.add(ball)

material = Mittsu::LineBasicMaterial.new(color: 0xff00ff)

geometry = Mittsu::Geometry.new()
NP = 10000
MD = 10.0
NR = 200
NP.times do |i|
	d = (i.to_f / NP) * MD
	r = (i.to_f / NP) * Math::PI * NR
	x = Math.sin(r) * d
	y = Math.cos(r) * d
	geometry.vertices.push(Mittsu::Vector3.new(x, y, 0.0))
end

line = Mittsu::Line.new(geometry, material)
scene.add(line)

camera.position.z = 5.0
camera.position.y = 0.0
camera.look_at(line.position)

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

x = 0
renderer.window.run do
  # break if x > 0
  x += 1
	line.rotation.z = x * 0.1

  renderer.render(scene, camera)
end
