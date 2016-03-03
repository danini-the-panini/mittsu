require 'minitest_helper'

class TestDirLightSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestDirLightSanityCheck'

    geometry = Mittsu::SphereGeometry.new(1.0)
    material = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
    cube = Mittsu::Mesh.new(geometry, material)
    scene.add(cube)

    light = Mittsu::DirectionalLight.new(0xffffff, 0.5)
    light.position.set(0.5, 1.0, 0.0)
    light_object = Mittsu::Object3D.new
    light_object.add(light)
    scene.add(light_object)

    camera.position.z = 5.0

    renderer.window.run do
      light_object.rotation.x += 0.1
      light_object.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
