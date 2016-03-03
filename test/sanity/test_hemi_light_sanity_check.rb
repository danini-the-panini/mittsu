require 'minitest_helper'

class TestHemiLightSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestHemiLightSanityCheck'

    geometry = Mittsu::SphereGeometry.new(1.0)
    material = Mittsu::MeshLambertMaterial.new(color: 0xffffff)
    cube = Mittsu::Mesh.new(geometry, material)
    scene.add(cube)

    light = Mittsu::HemisphereLight.new(0xCCF2FF, 0x055E00, 0.5)
    scene.add(light)

    camera.position.z = 5.0

    renderer.window.run do
      renderer.render(scene, camera)
    end
  end
end
