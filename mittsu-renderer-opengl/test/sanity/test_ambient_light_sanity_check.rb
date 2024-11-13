require 'minitest_helper'

class TestAmbientLightSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestAmbientLightSanityCheck'

    geometry = Mittsu::SphereGeometry.new(1.0)
    material = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
    cube = Mittsu::Mesh.new(geometry, material)
    scene.add(cube)

    light = Mittsu::AmbientLight.new(0x404040) # soft white light
    scene.add(light)

    camera.position.z = 5.0

    renderer.window.run do
      cube.rotation.x += 0.1
      cube.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
