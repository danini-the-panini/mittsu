require 'minitest_helper'

class TestOBJMTLLoader < Minitest::Test
  def test_load
    loader = Mittsu::OBJMTLLoader.new

    object = loader.load(File.expand_path('../../support/samples/test.obj', __FILE__), 'test.mtl')

    material = object.children.first.children.first.material

    assert_kind_of Mittsu::Material, material
    assert_color_equal Mittsu::Color.new(0.4, 0.5, 0.6), material.color
    assert_color_equal Mittsu::Color.new(0.7, 0.8, 0.9), material.specular
    assert_in_delta 123.45, material.shininess
    assert_in_delta 0.123, material.opacity
  end
end
