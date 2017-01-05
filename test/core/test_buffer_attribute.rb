require 'minitest_helper'

class TestBufferAttribute < Minitest::Test
  def test_length_reflects_array_length
    a = Mittsu::BufferAttribute.new([1,2,3], 1)

    assert_equal 3, a.length
  end

  def test_copy_at
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0], 2)
    b = Mittsu::BufferAttribute.new([1, 2, 3, 4, 5, 6, 7, 8, 9], 3)

    result = a.copy_at 1, b, 2

    assert_equal [0, 0, 7, 8, 0], a.array
    assert_equal a, result
  end

  def test_set
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set([1, 2, 3], 2)

    assert_equal [0, 0, 1, 2, 3, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_x
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set_x 1, 42

    assert_equal [0, 0, 0, 42, 0, 0, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_y
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set_y 1, 42

    assert_equal [0, 0, 0, 0, 42, 0, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_z
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set_z 1, 42

    assert_equal [0, 0, 0, 0, 0, 42, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_xy
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set_xy 1, 42, 24

    assert_equal [0, 0, 0, 42, 24, 0, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_xyz
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0], 3)

    result = a.set_xyz 1, 42, 24, 12

    assert_equal [0, 0, 0, 42, 24, 12, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_set_xyzw
    a = Mittsu::BufferAttribute.new([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 4)

    result = a.set_xyzw 1, 42, 24, 12, 6

    assert_equal [0, 0, 0, 0, 42, 24, 12, 6, 0, 0, 0, 0], a.array
    assert_equal a, result
  end

  def test_clone
    a = Mittsu::BufferAttribute.new([1,2,3,4,5,6], 3)

    b = a.clone

    assert_equal a.array, b.array
    refute_same a.array, b.array
    assert_equal a.item_size, b.item_size
  end
end
