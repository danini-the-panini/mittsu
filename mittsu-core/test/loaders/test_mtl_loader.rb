require 'minitest_helper'

class TestMTLLoader < Minitest::Test
  def test_load
    loader = Mittsu::MTLLoader.new(File.expand_path('../../support/samples', __FILE__))

    material = loader.load('test.mtl').create('test_material')

    assert_kind_of Mittsu::Material, material
    assert_color_equal Mittsu::Color.new(0.4, 0.5, 0.6), material.color
    assert_color_equal Mittsu::Color.new(0.7, 0.8, 0.9), material.specular
    assert_in_delta 123.45, material.shininess
    assert_in_delta 0.123, material.opacity
  end

  def test_load_normalize_rgb
    loader = Mittsu::MTLLoader.new(
      File.expand_path('../../support/samples', __FILE__),
      normalize_rgb: true
    )

    material = loader.load('test_rgb.mtl').create('test_material')

    assert_color_equal Mittsu::Color.new(40.0 / 255.0, 50.0 / 255.0, 60.0 / 255.0), material.color
    assert_color_equal Mittsu::Color.new(70.0 / 255.0, 80.0 / 255.0, 90.0 / 255.0), material.specular
  end

  def test_load_ignore_zero_rgbs
    loader = Mittsu::MTLLoader.new(
      File.expand_path('../../support/samples', __FILE__),
      ignore_zero_rgbs: true
    )

    material = loader.load('test_zero_rgb.mtl').create('test_material')

    assert_color_equal Mittsu::Color.new(1.0, 1.0, 1.0), material.color
    assert_color_equal Mittsu::Color.new(0.7, 0.8, 0.9), material.specular
  end

  def test_load_invert_transparency
    loader = Mittsu::MTLLoader.new(
      File.expand_path('../../support/samples', __FILE__),
      invert_transparency: true
    )

    material = loader.load('test.mtl').create('test_material')

    assert_in_delta 0.877, material.opacity
  end
end
