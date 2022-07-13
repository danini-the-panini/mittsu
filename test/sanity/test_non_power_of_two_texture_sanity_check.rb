require 'minitest_helper'

class TestNonPowerOfTwoTextureSanityCheck < Minitest::Test
  def test_that_it_works
    width = 800
    height = 600
    aspect = width.to_f / height.to_f

    scene = Mittsu::Scene.new
    camera = Mittsu::PerspectiveCamera.new(75.0, aspect, 0.1, 1000.0)

    renderer = Mittsu::OpenGLRenderer.new width: width, height: height, title: 'TestTextureSanityCheck'

    geometry = Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    texture = Mittsu::ImageUtils.load_texture(File.expand_path "../../support/samples/test_3x5.png", __FILE__)
    texture.wrap_s = Mittsu::RepeatWrapping
    texture.wrap_t = Mittsu::RepeatWrapping
    texture.min_filter = Mittsu::LinearMipMapLinearFilter
    material = Mittsu::MeshBasicMaterial.new(map: texture, normal_map: texture)
    cube = Mittsu::Mesh.new(geometry, material)
    scene.add(cube)

    camera.position.z = 5.0

    renderer.window.run do
      cube.rotation.x += 0.1
      cube.rotation.y += 0.1

      renderer.render(scene, camera)
    end
  end
end
