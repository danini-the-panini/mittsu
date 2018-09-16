require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f
TWO_PI = Math::PI * 2.0

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '02 Geometries Example'

geometries = [
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::SphereGeometry.new(1.0),
  Mittsu::RingGeometry.new(0.5, 1.0, 16, 4, 0.0, Math::PI*1.2),
  Mittsu::RingGeometry.new(0.5, 1.0),
  Mittsu::CircleGeometry.new(1.0, 8, 0.0, Math::PI * 1.3),
  Mittsu::CircleGeometry.new(1.0, 8),
  Mittsu::CylinderGeometry.new(1.0, 1.0, 2.0),
  Mittsu::DodecahedronGeometry.new,
  Mittsu::IcosahedronGeometry.new,
  Mittsu::OctahedronGeometry.new,
  Mittsu::TetrahedronGeometry.new,
  Mittsu::PlaneGeometry.new(1.0, 1.0)
]

colors = [
  0x00ff00,
  0xff0000,
  0x0000ff,
  0xff00ff,
  0xffff00,
  0x00ffff
]

meshes = geometries.each_with_index.map do |geometry, i|
  material = Mittsu::MeshBasicMaterial.new(color: colors[i % colors.length])
  mesh = Mittsu::Mesh.new(geometry, material)
  mesh.position.x = Math.sin((i.to_f / geometries.length.to_f) * TWO_PI) * 5.0
  mesh.position.y = Math.cos((i.to_f / geometries.length.to_f) * TWO_PI) * 5.0
  scene.add(mesh)
  mesh
end

camera.position.z = 10.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

renderer.window.run do
  meshes.each do |mesh|
    mesh.rotation.x += 0.1
    mesh.rotation.y += 0.1
  end

  renderer.render(scene, camera)
end
