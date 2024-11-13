require 'minitest_helper'

class TestPointCloudSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestBoxGeometrySanityCheck'

    geometry = Mittsu::Geometry.new
    100.times do |i|
      vertex = Mittsu::Vector3.new();
      vertex.x = rand * 2000.0 - 1000.0
      vertex.y = rand * 2000.0 - 1000.0
      vertex.z = rand * 2000.0 - 1000.0
      geometry.vertices << vertex
    end

    material = Mittsu::PointCloudMaterial.new()
    particles = Mittsu::PointCloud.new(geometry, material)

    scene.add(particles)

    camera.position.z = 5.0

    renderer.window.run do
      particles.rotation.x += 0.1
      particles.rotation.y += 0.1
      renderer.render(scene, camera)
    end
  end
end
