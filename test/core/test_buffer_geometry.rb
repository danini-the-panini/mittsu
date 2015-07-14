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
    assert_equal([], a.attributes_keys)

    assert_equal([], a.draw_calls)
    assert_nil a.bounding_box
    assert_nil a.bounding_sphere
  end

  def test_add_attribute
    a = Mittsu::BufferGeometry.new

    a.add_attribute :foobar, 'FOOBAR_ATTRIBUTE'
    a.add_attribute :quxbaz, 'QUXBAZ_ATTRIBUTE'

    assert_equal 'FOOBAR_ATTRIBUTE', a.attributes[:foobar]
    assert_equal 'QUXBAZ_ATTRIBUTE', a.attributes[:quxbaz]
    assert_equal 2, a.attributes_keys.length
    assert_includes a.attributes_keys, :foobar
    assert_includes a.attributes_keys, :quxbaz

    a.add_attribute :norfwat, 'NORFWAT_ATTRIBUTE'
    assert_equal 'NORFWAT_ATTRIBUTE', a.attributes[:norfwat]
    assert_equal 3, a.attributes_keys.length
    assert_includes a.attributes_keys, :norfwat
  end

  def test_get_attribute
    a = Mittsu::BufferGeometry.new

    a.add_attribute :foobar, 'FOOBAR_ATTRIBUTE'
    a.add_attribute :quxbaz, 'QUXBAZ_ATTRIBUTE'

    assert_equal 'FOOBAR_ATTRIBUTE', a.get_attribute(:foobar)
    assert_equal 'QUXBAZ_ATTRIBUTE', a.get_attribute(:quxbaz)
  end

  def test_add_draw_call
    a = Mittsu::BufferGeometry.new

    a.add_draw_call 1, 5, 7

    assert_equal 1, a.draw_calls.length
    assert_equal({start: 1, count: 5, index: 7}, a.draw_calls.last)

    a.add_draw_call 2, 7, 9

    assert_equal 2, a.draw_calls.length
    assert_equal({start: 1, count: 5, index: 7}, a.draw_calls.first)
    assert_equal({start: 2, count: 7, index: 9}, a.draw_calls.last)
  end

  def test_add_draw_call_without_index_offset
    a = Mittsu::BufferGeometry.new

    a.add_draw_call 1, 5

    assert_equal 1, a.draw_calls.length
    assert_equal({start: 1, count: 5, index: 0}, a.draw_calls.last)
  end

  def test_apply_matrix
    skip
    a = Mittsu::BufferGeometry.new
    position = Mittsu::BufferAttribute.new()
    normal = Mittsu::BufferAttribute.new()

    a.add_attribute :position, position
    a.add_attribute :normal, normal

    m = Minitest::Mock.new
    m.expect :apply_to_vector_3_array

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
