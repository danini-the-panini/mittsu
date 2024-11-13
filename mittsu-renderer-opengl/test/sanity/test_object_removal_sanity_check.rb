require 'minitest_helper'

class TestObjectRemovalSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestObjectRemovalSanityCheck'

    geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)
    cube = Mittsu::Mesh.new(geometry, material)
    scene.add(cube)
    assert_includes scene.children, cube

    camera.position.z = 5.0

    renderer.window.run do
      cube.rotation.x += 0.1
      cube.rotation.y += 0.1
      renderer.render(scene, camera)

      scene.remove(cube)
      refute_includes scene.children, cube

      renderer.render(scene, camera)

      scene.add(cube)
      assert_includes scene.children, cube

      renderer.render(scene, camera)
    end
  end
end
