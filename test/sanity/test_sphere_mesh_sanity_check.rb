require 'minitest_helper'

class TestSphereMeshSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestSphereMeshSanityCheck'

    geometry = Mittsu::SphereGeometry.new(1.0)
    material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
    sphere = Mittsu::Mesh.new(geometry, material)
    scene.add(sphere)

    camera.position.z = 5.0

    renderer.window.run do
      sphere.rotation.x += 0.1
      sphere.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
