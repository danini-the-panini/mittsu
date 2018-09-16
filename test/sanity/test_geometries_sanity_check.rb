require 'minitest_helper'

class TestGeometriesSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestGeometriesSanityCheck'

    material = Mittsu::MeshBasicMaterial.new(color: 0x00ff00)

    [
      Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
      Mittsu::SphereGeometry.new(1.0),
      Mittsu::RingGeometry.new,
      Mittsu::CircleGeometry.new,
      Mittsu::CylinderGeometry.new,
      Mittsu::DodecahedronGeometry.new,
      Mittsu::IcosahedronGeometry.new,
      Mittsu::OctahedronGeometry.new,
      Mittsu::TetrahedronGeometry.new,
      Mittsu::PlaneGeometry.new(1.0, 1.0),
      Mittsu::TorusGeometry.new
    ].each do |geom|
      mesh = Mittsu::Mesh.new(geom, material)
      scene.add(mesh)
    end

    camera.position.z = 5.0

    renderer.window.run do
      renderer.render(scene, camera)
    end
  end
end
