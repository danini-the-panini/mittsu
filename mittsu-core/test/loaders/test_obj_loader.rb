require 'minitest_helper'

class TestOBJLoader < Minitest::Test
  def test_parse
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

f 1 2 4
f 2 3 4
"""

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
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    [
      [0, 1, 3],
      [1, 2, 3]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0]
      b = f[1]
      c = f[2]

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)
    }
  end

  def test_parse_with_quads
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

f 1 2 3 4
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    assert_equal 2, square_mesh.geometry.faces.length
    [
      [0, 1, 3],
      [1, 2, 3]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a, b, c = *f

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)
    }
  end

  def test_parse_with_uvs
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vt 0.0 0.0
vt 0.0 1.0
vt 1.0 0.0
vt 1.0 1.0

f 1/2 2/1 4/4
f 2/1 3/3 4/4
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    uvs = [
      Mittsu::Vector2.new(0.0, 0.0),
      Mittsu::Vector2.new(0.0, 1.0),
      Mittsu::Vector2.new(1.0, 0.0),
      Mittsu::Vector2.new(1.0, 1.0)
    ]
    [
      [[0, 2], [1, 1], [3, 4]],
      [[1, 1], [2, 3], [3, 4]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0]
      b = f[1][0]
      c = f[2][0]

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| uvs[ff[1] - 1] }.each_with_index { |uv, j|
        assert_equal uv, square_mesh.geometry.face_vertex_uvs[0][i][j]
      }
    }
  end

  def test_parse_quads_with_uvs
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vt 0.0 0.0
vt 0.0 1.0
vt 1.0 0.0
vt 1.0 1.0

f 1/2 2/1 3/3 4/4
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    uvs = [
      Mittsu::Vector2.new(0.0, 0.0),
      Mittsu::Vector2.new(0.0, 1.0),
      Mittsu::Vector2.new(1.0, 0.0),
      Mittsu::Vector2.new(1.0, 1.0)
    ]
    [
      [[0, 2], [1, 1], [3, 4]],
      [[1, 1], [2, 3], [3, 4]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0]
      b = f[1][0]
      c = f[2][0]

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| uvs[ff[1] - 1] }.each_with_index { |uv, j|
        assert_equal uv, square_mesh.geometry.face_vertex_uvs[0][i][j]
      }
    }
  end

  def test_parse_with_normals
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vn  0.0  1.0 0.0
vn  1.0  0.0 0.0
vn -1.0  0.0 0.0
vn  0.0 -1.0 0.0

f 1//3 2//4 4//1
f 2//4 3//2 4//1
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    normals = [
      Mittsu::Vector3.new( 0.0,  1.0, 0.0),
      Mittsu::Vector3.new( 1.0,  0.0, 0.0),
      Mittsu::Vector3.new(-1.0,  0.0, 0.0),
      Mittsu::Vector3.new( 0.0, -1.0, 0.0)
    ]
    [
      [[1, 3], [2, 4], [4, 1]],
      [[2, 4], [3, 2], [4, 1]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0] - 1
      b = f[1][0] - 1
      c = f[2][0] - 1

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| normals[ff[1] - 1] }.each_with_index { |vn, j|
        assert_equal vn, face.vertex_normals[j]
      }
      assert_equal Mittsu::Vector3.new(0.0, 0.0, 1.0), face.normal
    }
  end

  def test_parse_quads_with_normals
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vn  0.0  1.0 0.0
vn  1.0  0.0 0.0
vn -1.0  0.0 0.0
vn  0.0 -1.0 0.0

f 1//3 2//4 3//2 4//1
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    normals = [
      Mittsu::Vector3.new( 0.0,  1.0, 0.0),
      Mittsu::Vector3.new( 1.0,  0.0, 0.0),
      Mittsu::Vector3.new(-1.0,  0.0, 0.0),
      Mittsu::Vector3.new( 0.0, -1.0, 0.0)
    ]
    [
      [[1, 3], [2, 4], [4, 1]],
      [[2, 4], [3, 2], [4, 1]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0] - 1
      b = f[1][0] - 1
      c = f[2][0] - 1

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| normals[ff[1] - 1] }.each_with_index { |vn, j|
        assert_equal vn, face.vertex_normals[j]
      }
      assert_equal Mittsu::Vector3.new(0.0, 0.0, 1.0), face.normal
    }
  end

  def test_parse_with_uvs_and_normals
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vn  0.0  1.0 0.0
vn  1.0  0.0 0.0
vn -1.0  0.0 0.0
vn  0.0 -1.0 0.0

vt 0.0 0.0
vt 0.0 1.0
vt 1.0 0.0
vt 1.0 1.0

f 1/2/3 2/1/4 4/4/1
f 2/1/4 3/3/2 4/4/1
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    uvs = [
      Mittsu::Vector2.new(0.0, 0.0),
      Mittsu::Vector2.new(0.0, 1.0),
      Mittsu::Vector2.new(1.0, 0.0),
      Mittsu::Vector2.new(1.0, 1.0)
    ]
    normals = [
      Mittsu::Vector3.new( 0.0,  1.0, 0.0),
      Mittsu::Vector3.new( 1.0,  0.0, 0.0),
      Mittsu::Vector3.new(-1.0,  0.0, 0.0),
      Mittsu::Vector3.new( 0.0, -1.0, 0.0)
    ]
    [
      [[1, 2, 3], [2, 1, 4], [4, 4, 1]],
      [[2, 1, 4], [3, 3, 2], [4, 4, 1]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0] - 1
      b = f[1][0] - 1
      c = f[2][0] - 1

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| uvs[ff[1] - 1] }.each_with_index { |uv, j|
        assert_equal uv, square_mesh.geometry.face_vertex_uvs[0][i][j]
      }

      f.map { |ff| normals[ff[2] - 1] }.each_with_index { |vn, j|
        assert_equal vn, face.vertex_normals[j]
      }
      assert_equal Mittsu::Vector3.new(0.0, 0.0, 1.0), face.normal
    }
  end

  def test_parse_quads_with_uvs_and_normals
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

vn  0.0  1.0 0.0
vn  1.0  0.0 0.0
vn -1.0  0.0 0.0
vn  0.0 -1.0 0.0

vt 0.0 0.0
vt 0.0 1.0
vt 1.0 0.0
vt 1.0 1.0

f 1/2/3 2/1/4 3/3/2 4/4/1
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 1, object.children.count

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    square_mesh = square.children.first
    assert_kind_of Mittsu::Geometry, square_mesh.geometry
    [
      Mittsu::Vector3.new(0.0, 2.0, 0.0),
      Mittsu::Vector3.new(0.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 0.0, 0.0),
      Mittsu::Vector3.new(2.0, 2.0, 0.0)
    ].each_with_index { |v, i|
      assert_equal v, square_mesh.geometry.vertices[i]
    }
    uvs = [
      Mittsu::Vector2.new(0.0, 0.0),
      Mittsu::Vector2.new(0.0, 1.0),
      Mittsu::Vector2.new(1.0, 0.0),
      Mittsu::Vector2.new(1.0, 1.0)
    ]
    normals = [
      Mittsu::Vector3.new( 0.0,  1.0, 0.0),
      Mittsu::Vector3.new( 1.0,  0.0, 0.0),
      Mittsu::Vector3.new(-1.0,  0.0, 0.0),
      Mittsu::Vector3.new( 0.0, -1.0, 0.0)
    ]
    [
      [[1, 2, 3], [2, 1, 4], [4, 4, 1]],
      [[2, 1, 4], [3, 3, 2], [4, 4, 1]]
    ].each_with_index { |f, i|
      face = square_mesh.geometry.faces[i]
      a = f[0][0] - 1
      b = f[1][0] - 1
      c = f[2][0] - 1

      assert_equal(a, face.a)
      assert_equal(b, face.b)
      assert_equal(c, face.c)

      f.map { |ff| uvs[ff[1] - 1] }.each_with_index { |uv, j|
        assert_equal uv, square_mesh.geometry.face_vertex_uvs[0][i][j]
      }

      f.map { |ff| normals[ff[2] - 1] }.each_with_index { |vn, j|
        assert_equal vn, face.vertex_normals[j]
      }
      assert_equal Mittsu::Vector3.new(0.0, 0.0, 1.0), face.normal
    }
  end

  def test_parse_with_objects
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

o square1

f 1 2 4
f 2 3 4

o square2

v 0.0 2.0 0.0
v 0.0 0.0 0.0
v 2.0 0.0 0.0
v 2.0 2.0 0.0

f 5 6 8
f 6 7 8
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 2, object.children.count

    object.children.each_with_index do |square, i|
      assert_equal "square#{i+1}", square.name

      assert_kind_of Mittsu::Object3D, square
      assert_equal 1, square.children.count, "#{square.name} children"

      square_mesh = square.children.first
      assert_kind_of Mittsu::Geometry, square_mesh.geometry, "#{square.name} geometry"
      assert_equal square.name, square_mesh.name, "#{square.name} geometry name"

      [
        Mittsu::Vector3.new(0.0, 1.0, 0.0).multiply_scalar(i+1),
        Mittsu::Vector3.new(0.0, 0.0, 0.0).multiply_scalar(i+1),
        Mittsu::Vector3.new(1.0, 0.0, 0.0).multiply_scalar(i+1),
        Mittsu::Vector3.new(1.0, 1.0, 0.0).multiply_scalar(i+1)
      ].each_with_index { |v, j|
        assert_equal v, square_mesh.geometry.vertices[j], "#{square.name} vertex #{j}"
      }
    end
  end

  def test_parse_with_materials
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
usemtl test_material

v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

f 1 2 4
f 2 3 4
"""

    assert_kind_of Mittsu::Group, object

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 1, square.children.count

    assert_equal 'test_material', square.children.first.material.name
  end

  def test_parse_with_multiple_materials
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
o square

v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

usemtl test_material1
f 1 2 4
usemtl test_material2
f 2 3 4
"""

    assert_kind_of Mittsu::Group, object

    square = object.children.first
    assert_kind_of Mittsu::Object3D, square
    assert_equal 2, square.children.count

    assert_equal 'square', square.name

    assert_equal 'square test_material1', square.children[0].name
    assert_equal 'square test_material2', square.children[1].name

    assert_equal 'test_material1', square.children[0].material.name
    assert_equal 'test_material2', square.children[1].material.name
  end

  def test_parse_object_with_materials
    loader = Mittsu::OBJLoader.new

    object = loader.parse """
o square1
usemtl test_material

v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

f 1 2 4
f 2 3 4

o square2

v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

f 5 6 8
f 6 7 8

o square3
usemtl test_material2

v 0.0 1.0 0.0
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0

f  9 10 12
f 10 11 12
"""

    assert_kind_of Mittsu::Group, object
    assert_equal 3, object.children.count

    assert_equal 'test_material', object.children[0].children.first.material.name
    assert_equal 'test_material', object.children[1].children.first.material.name
    assert_equal 'test_material2', object.children[2].children.first.material.name
  end

  def test_parse_with_error
    loader = Mittsu::OBJLoader.new

    assert_raises('Mittsu::OBJLoader: Unhandled line 5') { loader.parse """
o foo

v 1 2 3
nope 3 4 5
""" }
  end
end
