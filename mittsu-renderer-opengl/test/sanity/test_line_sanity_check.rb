require 'minitest_helper'

class TestLineSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: '09 Line Example'

    ball = Mittsu::Mesh.new(
      Mittsu::SphereGeometry.new(0.1),
      Mittsu::MeshBasicMaterial.new(color: 0xff00ff)
    )
    scene.add(ball)

    material = Mittsu::LineBasicMaterial.new(color: 0xff00ff)

    geometry = Mittsu::Geometry.new()
    np = 10000
    md = 10.0
    nr = 200
    np.times do |i|
    	d = (i.to_f / np) * md
    	r = (i.to_f / np) * ::Math::PI * nr
    	x = ::Math.sin(r) * d
    	y = ::Math.cos(r) * d
    	geometry.vertices.push(Mittsu::Vector3.new(x, y, 0.0))
    end

    line = Mittsu::Line.new(geometry, material)
    scene.add(line)

    camera.position.z = 5.0
    camera.position.y = 0.0
    camera.look_at(line.position)

    x = 0
    renderer.window.run do
      # break if x > 0
      x += 1
    	line.rotation.z = x * 0.1

      renderer.render(scene, camera)
    end
  end
end
