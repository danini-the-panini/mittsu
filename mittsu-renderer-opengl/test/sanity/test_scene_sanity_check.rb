require 'minitest_helper'

class TestSceneSanityCheck < Minitest::Test
  def test_that_it_works
    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, 1.0, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: 100, height: 100, title: 'TestSceneSanityCheck'

    renderer.window.run do
      renderer.render(scene, camera)
    end
  end
end
