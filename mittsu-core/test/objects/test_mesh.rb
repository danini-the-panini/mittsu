require 'minitest_helper'

class TestMesh < Minitest::Test
  def test_initialize_default
    mesh = Mittsu::Mesh.new

    assert_kind_of Mittsu::Geometry, mesh.geometry
    assert_kind_of Mittsu::MeshBasicMaterial, mesh.material
    assert_equal 'Mesh', mesh.type
  end

  def test_clone
    mesh = Mittsu::Mesh.new

    mesh2 = mesh.clone

    refute_equal mesh, mesh2
    assert_equal mesh.geometry, mesh2.geometry
    assert_equal mesh.material, mesh2.material
  end

  def test_to_json
    mesh = Mittsu::Mesh.new

    json = mesh.to_json

    assert_equal({
      metadata: {
        version: 4.3,
        type: 'Object',
        generator: 'ObjectExporter'
      },
      geometries: [{
        uuid: mesh.geometry.uuid,
        type: 'Geometry',
        data: {
          vertices: [],
          normals: [],
          faces: []
        }
      }],
      materials: [{
        uuid: mesh.material.uuid,
        type: 'MeshBasicMaterial'
      }],
      object: {
        uuid: mesh.uuid,
        type: 'Mesh',
        geometry: mesh.geometry.uuid,
        material: mesh.material.uuid,
        matrix: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
      }
    }, json)
  end
end
