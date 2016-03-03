require 'minitest_helper'

class TestPointLightSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestPointLightSanityCheck'

    sphere_geometry = Mittsu::SphereGeometry.new(1.0)
    box_geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    green_material = Mittsu::MeshPhongMaterial.new(color: 0x00ff00)
    blue_material = Mittsu::MeshPhongMaterial.new(color: 0x0000ff)
    magenta_material = Mittsu::MeshPhongMaterial.new(color: 0xff00ff)
    cube = Mittsu::Mesh.new(box_geometry, green_material)
    sphere1 = Mittsu::Mesh.new(sphere_geometry, blue_material)
    sphere1.position.set(3.0, 0.0, 0.0)
    sphere2 = Mittsu::Mesh.new(sphere_geometry, magenta_material)
    sphere2.position.set(-3.0, 0.0, 0.0)

    scene.add(cube)
    scene.add(sphere1)
    scene.add(sphere2)

    room_material = Mittsu::MeshPhongMaterial.new(color: 0xffffff)
    room_material.side = Mittsu::BackSide
    room = Mittsu::Mesh.new(box_geometry, room_material)
    room.scale.set(10.0, 10.0, 10.0)
    scene.add(room)

    light = Mittsu::PointLight.new(0xffffff, 0.5, 10.0, 1.5)
    dot = Mittsu::Mesh.new(box_geometry, Mittsu::MeshBasicMaterial.new(color: 0xffffff))
    dot.scale.set(0.1, 0.1, 0.1)
    light.add(dot)
    light.position.set(0.0, 1.5, 0.0)
    light_object = Mittsu::Object3D.new
    light_object.add(light)
    scene.add(light_object)

    camera.position.z = 5.0

    renderer.window.run do
      light_object.rotation.z += 0.1
      cube.rotation.x += 0.1
      cube.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
