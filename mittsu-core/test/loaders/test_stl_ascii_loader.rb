require 'minitest_helper'

class TestSTLASCIILoader < Minitest::Test
  def test_parse
    loader = Mittsu::STLLoader.new

    object = loader.parse """solid
  facet normal 0 0 1
    outer loop
      vertex -1 100.0e-2 0
      vertex -1 -1e0 0
      vertex 1 100.0e-2 0
    endloop
  endfacet
  facet normal 0 0 1
    outer loop
      vertex -1 -1e0 0
      vertex 1 -1e0 0
      vertex 1 100.0e-2 0
    endloop
  endfacet
endsolid
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square_mesh = object.children.first
    assert_kind_of Mittsu::Mesh, square_mesh
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(-1.0, 1.0, 0),
      Mittsu::Vector3.new(-1.0, -1.0, 0),
      Mittsu::Vector3.new(1.0, 1.0, 0),
      Mittsu::Vector3.new(1.0, -1.0, 0)
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

  def test_parse_with_error
    loader = Mittsu::STLLoader.new

    assert_raises('Mittsu::STLLoader: Unhandled line 3') { loader.parse """solid
  facet normal 0 0 1
    broken
    outer loop
      vertex -1 1 -1
      vertex -1 -1 -1
      vertex 1 1 -1
    endloop
  endfacet
endsolid
""" }
  end


  def test_parse_multiple_solids
    loader = Mittsu::STLLoader.new

    object = loader.parse """solid
  facet normal 0 0 1
    outer loop
      vertex -1 100.0e-2 0
      vertex -1 -1e0 0
      vertex 1 100.0e-2 0
    endloop
  endfacet
endsolid
solid
  facet normal 0 0 1
    outer loop
      vertex -1 -1e0 0
      vertex 1 -1e0 0
      vertex 1 100.0e-2 0
    endloop
  endfacet
endsolid
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 2, object.children.count
  end
end
