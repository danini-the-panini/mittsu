require 'minitest_helper'
require 'minitest/mock'

class TestBufferGeometry < Minitest::Test
  def test_id
    a = Mittsu::BufferGeometry.new
    b = Mittsu::BufferGeometry.new

    assert_equal(a.id + 1, b.id)
  end

  def test_uuid
    a = Mittsu::BufferGeometry.new
    b = Mittsu::BufferGeometry.new

    refute_equal a.uuid, b.uuid
  end

  def test_init
    a = Mittsu::BufferGeometry.new

    assert_equal '', a.name
    assert_equal 'BufferGeometry', a.type

    assert_equal({}, a.attributes)
    assert_equal([], a.keys)

    assert_equal([], a.draw_calls)
    assert_nil a.bounding_box
    assert_nil a.bounding_sphere
  end

  def test_add_attribute
    a = Mittsu::BufferGeometry.new

    a[:foobar] = 'FOOBAR_ATTRIBUTE'

    assert_equal 'FOOBAR_ATTRIBUTE', a.attributes[:foobar]
    assert_includes a.keys, :foobar
  end

  def test_get_attribute
    a = Mittsu::BufferGeometry.new

    a.attributes[:foobar] = 'FOOBAR_ATTRIBUTE'

    assert_equal 'FOOBAR_ATTRIBUTE', a[:foobar]
  end

  def test_add_draw_call
    a = Mittsu::BufferGeometry.new

    a.add_draw_call 1, 5, 7

    assert_equal 1, a.draw_calls.length
    draw_call = a.draw_calls.last
    assert_equal 1, draw_call.start
    assert_equal 5, draw_call.count
    assert_equal 7, draw_call.index
  end

  def test_add_draw_call_without_index_offset
    a = Mittsu::BufferGeometry.new

    a.add_draw_call 1, 5

    assert_equal 1, a.draw_calls.length
    draw_call = a.draw_calls.last
    assert_equal 1, draw_call.start
    assert_equal 5, draw_call.count
    assert_equal 0, draw_call.index
  end

  def test_apply_matrix
    # skip
    a = Mittsu::BufferGeometry.new
    position = Mittsu::BufferAttribute.new([], 3)
    normal = Mittsu::BufferAttribute.new([], 3)

    a[:position] = position
    a[:normal] = normal

    m = Mittsu::Matrix4.new

    a.apply_matrix m

    assert position.needs_update
    assert normal.needs_update
  end

  def test_center
    skip
  end

  def test_from_geometry
    skip
  end

  def test_compute_bounding_box
    skip
  end

  def test_compute_bounding_sphere
    skip
  end

  def test_compute_vertex_normals
    skip
  end

  def test_compute_tangents
    skip
  end

  def test_compute_offsets
    skip
  end

  def test_merge
    skip
  end

  def test_normalize_normals
    skip
  end

  def test_reorder_buffers
    skip
  end

  def test_to_json
    skip
  end

  def test_clone
    skip
  end

  def test_dispose
    skip
  end
end
