require_relative './example_helper'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

PARTICLE_COUNT = 20000

scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: '17 Point Cloud Example'

geometry = Mittsu::Geometry.new
PARTICLE_COUNT.times do |i|
  vertex = Mittsu::Vector3.new();
  vertex.x = rand * 2000.0 - 1000.0
  vertex.y = rand * 2000.0 - 1000.0
  vertex.z = rand * 2000.0 - 1000.0
  geometry.vertices << vertex
end

parameters = [
  [
      [1, 1, 0.5], 5
  ],
  [
      [0.95, 1, 0.5], 4
  ],
  [
      [0.90, 1, 0.5], 3
  ],
  [
      [0.85, 1, 0.5], 2
  ],
  [
      [0.80, 1, 0.5], 1
  ]
]

materials = []
parameters.each_with_index do |(_, size), i|
  materials[i] = Mittsu::PointCloudMaterial.new(size: size )

  particles = Mittsu::PointCloud.new(geometry, materials[i])

  particles.rotation.x = rand * 6.0;
  particles.rotation.y = rand * 6.0;
  particles.rotation.z = rand * 6.0;

  scene.add(particles)
end

camera.position.z = 5.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
end

time = 0
renderer.window.run do
  scene.children.each_with_index do |object, i|
    next unless object.is_a? Mittsu::PointCloud
    object.rotation.y = time * (i < 4 ? i + 1.0 : -(i + 1.0))
  end

  materials.each_with_index do |material, i|
    color = parameters[i][0]
    h = (360.0 * (color[0] + time) % 360) / 360.0
    material.color.set_hsl(h, color[1], color[2])
  end

  renderer.render(scene, camera)
  time += 0.001
end
