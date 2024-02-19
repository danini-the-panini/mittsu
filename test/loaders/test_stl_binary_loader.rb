require 'minitest_helper'

class TestSTLBinaryLoader < Minitest::Test
  def test_parse_binary
    loader = Mittsu::STLLoader.new

    object = loader.parse File.read(
      File.join(File.dirname(__FILE__), "..", "support", "samples", "square.binary.stl")
    )

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Mesh, square_mesh
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    [
      [0, 1, 2],
      [1, 3, 2]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0]
      b = f[1]
      c = f[2]
      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)
      assert_equal(Mittsu::Vector3.new(0, 0, 1), face.normal)
    }
  end

end
