require 'minitest_helper'

class TestSpotLightSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestSpotLightSanityCheck'

    box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    sphere_geometry = Mittsu::SphereGeometry.new(1.0)
    floor_geometry = Mittsu::BoxGeometry.new(20.0, 0.1, 20.0, 20, 1, 20)
    green_material = Mittsu::MeshLambertMaterial.new(color: 0x00ff00)
    blue_material = Mittsu::MeshLambertMaterial.new(color: 0x0000ff)
    sphere = Mittsu::Mesh.new(sphere_geometry, blue_material)
    floor = Mittsu::Mesh.new(floor_geometry, green_material)
    floor.position.set(0.0, -2.0, 0.0)
    scene.add(sphere)
    scene.add(floor)

    light = Mittsu::SpotLight.new(0xffffff, 0.5, 10.0)
    light.position.set(3.0, 1.0, 0.0)
    dot = Mittsu::Mesh.new(box_geometry, Mittsu::MeshBasicMaterial.new(color: 0xffffff))
    dot.scale.set(0.1, 0.1, 0.1)
    light.add(dot)
    light_object = Mittsu::Object3D.new
    light_object.add(light)
    scene.add(light_object)

    camera.position.z = 5.0

    renderer.window.run do
      light_object.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
