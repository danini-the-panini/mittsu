require 'minitest_helper'

class TestLine < Minitest::Test
  def test_initialize_default
    line = Mittsu::Line.new

    assert_kind_of Mittsu::Geometry, line.geometry
    assert_kind_of Mittsu::LineBasicMaterial, line.material
    assert_equal 'Line', line.type
  end

  def test_clone
    line = Mittsu::Line.new

    line2 = line.clone

    refute_equal line, line2
    assert_equal line.geometry, line2.geometry
    assert_equal line.material, line2.material
  end

  def test_to_json
    line = Mittsu::Line.new

    json = line.to_json

    assert_equal({
      metadata: {
        version: 4.3,
        type: 'Object',
        generator: 'ObjectExporter'
      },
      geometries: [{
        uuid: line.geometry.uuid,
        type: 'Geometry',
        data: {
          vertices: [],
          normals: [],
          faces: []
        }
      }],
      materials: [{
        uuid: line.material.uuid,
        type: 'LineBasicMaterial'
      }],
      object: {
        uuid: line.uuid,
        type: 'Line',
        geometry: line.geometry.uuid,
        material: line.material.uuid,
        matrix: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
        mode: Mittsu::LineStrip
      }
    }, json)
  end
end
