require 'minitest_helper'

class TestVector2 < Minitest::Test

  def test_initialize
    a = Mittsu::Vector2.new(1.5, 2.3)
    assert_equal 1.5, a.x
    assert_equal 2.3, a.y

    a = Mittsu::Vector2.new(1.5)
    assert_equal 1.5, a.x
    assert_equal 0, a.y

    a = Mittsu::Vector2.new
    assert_equal 0, a.x
    assert_equal 0, a.y
  end

  def test_set
    a = Mittsu::Vector2.new

    result = a.set(1.5, 2.3)
    assert_equal 1.5, a.x
    assert_equal 2.3, a.y

    assert_equal a, result
  end

  def test_set_x
    a = Mittsu::Vector2.new

    a.x = 4.2
    assert_equal 4.2, a.x
    assert_equal 0, a.y
  end

  def test_set_y
    a = Mittsu::Vector2.new

    a.y = 4.2
    assert_equal 0, a.x
    assert_equal 4.2, a.y
  end

  def test_set_component
    a = Mittsu::Vector2.new

    a[0] = 4.2
    assert_equal 4.2, a.x
    assert_equal 0, a.y

    a[1] = 2.1
    assert_equal 4.2, a.x
    assert_equal 2.1, a.y

    assert_raises(IndexError) { a[-1] = 1.0 }
    assert_raises(IndexError) { a[2] = 1.0 }
  end

  def test_get_component
    a = Mittsu::Vector2.new(1.5, 2.3)

    assert_equal 1.5, a[0]
    assert_equal 2.3, a[1]

    assert_raises(IndexError) { a[-1] }
    assert_raises(IndexError) { a[2] }
  end

  def test_copy
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.copy(Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 3.4, a.x
    assert_equal 1.2, a.y

    assert_equal a, result
  end

  def test_add
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.add(Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 + 3.4, a.x
    assert_equal 2.3 + 1.2, a.y

    assert_equal a, result
  end

  def test_add_scalar
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.add_scalar(4.1)

    assert_equal 1.5 + 4.1, a.x
    assert_equal 2.3 + 4.1, a.y

    assert_equal a, result
  end

  def test_add_vectors
    a = Mittsu::Vector2.new

    result = a.add_vectors(Mittsu::Vector2.new(1.5, 2.3), Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 + 3.4, a.x
    assert_equal 2.3 + 1.2, a.y

    assert_equal a, result
  end

  def test_sub
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.sub(Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 - 3.4, a.x
    assert_equal 2.3 - 1.2, a.y

    assert_equal a, result
  end

  def test_sub_scalar
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.sub_scalar(4.1)

    assert_equal 1.5 - 4.1, a.x
    assert_equal 2.3 - 4.1, a.y

    assert_equal a, result
  end

  def test_sub_vectors
    a = Mittsu::Vector2.new

    result = a.sub_vectors(Mittsu::Vector2.new(1.5, 2.3), Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 - 3.4, a.x
    assert_equal 2.3 - 1.2, a.y

    assert_equal a, result
  end

  def test_multiply
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.multiply(Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 * 3.4, a.x
    assert_equal 2.3 * 1.2, a.y

    assert_equal a, result
  end

  def test_multiply_scalar
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.multiply_scalar(4.1)

    assert_equal 1.5 * 4.1, a.x
    assert_equal 2.3 * 4.1, a.y

    assert_equal a, result
  end

  def test_divide
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.divide(Mittsu::Vector2.new(3.4, 1.2))

    assert_equal 1.5 / 3.4, a.x
    assert_equal 2.3 / 1.2, a.y

    assert_equal a, result
  end

  def test_divide_scalar
    a = Mittsu::Vector2.new(1.5, 2.3)

    result = a.divide_scalar(4.1)

    assert_equal 1.5 / 4.1, a.x
    assert_equal 2.3 / 4.1, a.y

    assert_equal a, result
  end

  def test_min
    a = Mittsu::Vector2.new(1.5, 2.3)
    result = a.min(Mittsu::Vector2.new(0.3, 0.5))
    assert_equal 0.3, a.x
    assert_equal 0.5, a.y
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.min(Mittsu::Vector2.new(0.3, 3.5))
    assert_equal 0.3, a.x
    assert_equal 2.3, a.y

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.min(Mittsu::Vector2.new(2.3, 0.5))
    assert_equal 1.5, a.x
    assert_equal 0.5, a.y

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.min(Mittsu::Vector2.new(2.3, 3.5))
    assert_equal 1.5, a.x
    assert_equal 2.3, a.y
  end

  def test_max
    a = Mittsu::Vector2.new(1.5, 2.3)
    result = a.max(Mittsu::Vector2.new(0.3, 0.5))
    assert_equal 1.5, a.x
    assert_equal 2.3, a.y
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.max(Mittsu::Vector2.new(0.3, 3.5))
    assert_equal 1.5, a.x
    assert_equal 3.5, a.y

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.max(Mittsu::Vector2.new(2.3, 0.5))
    assert_equal 2.3, a.x
    assert_equal 2.3, a.y

    a = Mittsu::Vector2.new(1.5, 2.3)
    a.max(Mittsu::Vector2.new(2.3, 3.5))
    assert_equal 2.3, a.x
    assert_equal 3.5, a.y
  end

  def test_clamp
    a = Mittsu::Vector2.new(1.5, -3.4)
    result = a.clamp(Mittsu::Vector2.new(0.0, -1.0), Mittsu::Vector2.new(1.0, 1.0))
    assert_equal(1.0, a.x)
    assert_equal(-1.0, a.y)
    assert_equal a, result

    a = Mittsu::Vector2.new(0.5, -0.3)
    a.clamp(Mittsu::Vector2.new(0.0, -1.0), Mittsu::Vector2.new(1.0, 1.0))
    assert_equal(0.5, a.x)
    assert_equal(-0.3, a.y)

    a = Mittsu::Vector2.new(-1.2, 1.7)
    a.clamp(Mittsu::Vector2.new(0.0, -1.0), Mittsu::Vector2.new(1.0, 1.0))
    assert_equal(0.0, a.x)
    assert_equal(1.0, a.y)
  end

  def test_clamp_scalar
    a = Mittsu::Vector2.new(1.5, -3.4)
    result = a.clamp_scalar(0.0, 1.0)
    assert_equal 1.0, a.x
    assert_equal 0.0, a.y
    assert_equal a, result

    a = Mittsu::Vector2.new(0.5, 0.3)
    a.clamp_scalar(0.0, 1.0)
    assert_equal 0.5, a.x
    assert_equal 0.3, a.y
  end

  def test_floor
    a = Mittsu::Vector2.new(1.4, -3.4)
    result = a.floor
    assert_equal(1, a.x)
    assert_equal(-4, a.y)
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, -3.5)
    a.floor
    assert_equal(1, a.x)
    assert_equal(-4, a.y)
  end

  def test_ceil
    a = Mittsu::Vector2.new(1.4, -3.4)
    result = a.ceil
    assert_equal(2, a.x)
    assert_equal(-3, a.y)
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, -3.5)
    a.ceil
    assert_equal(2, a.x)
    assert_equal(-3, a.y)
  end

  def test_round
    a = Mittsu::Vector2.new(1.4, -3.4)
    result = a.round
    assert_equal(1, a.x)
    assert_equal(-3, a.y)
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, -3.5)
    a.round
    assert_equal(2, a.x)
    assert_equal(-4, a.y)
  end

  def test_round_to_zero
    a = Mittsu::Vector2.new(1.4, -3.4)
    result = a.round_to_zero
    assert_equal(1, a.x)
    assert_equal(-3, a.y)
    assert_equal a, result

    a = Mittsu::Vector2.new(1.5, -3.5)
    a.round_to_zero
    assert_equal(1, a.x)
    assert_equal(-3, a.y)
  end

  def test_negate
    a = Mittsu::Vector2.new(1.4, -3.4)

    result = a.negate

    assert_equal(-1.4, a.x)
    assert_equal(3.4, a.y)

    assert_equal a, result
  end

  def test_dot
    a = Mittsu::Vector2.new(1.4, -3.4)

    d = a.dot(Mittsu::Vector2.new(-2.3, 4.2))

    assert_in_delta(-17.5, d, DELTA)
  end

  def test_length_sq
    a = Mittsu::Vector2.new(1.4, -3.4)

    assert_in_delta(13.52, a.length_sq, DELTA)
  end

  def test_length
    a = Mittsu::Vector2.new(1.4, -3.4)

    assert_in_delta(3.676955262170047, a.length, DELTA)
  end

  def test_normalize
    a = Mittsu::Vector2.new(1.4, -3.4)

    result = a.normalize

    assert_in_delta(0.38074980525429, a.x, DELTA)
    assert_in_delta(-0.92467809847472, a.y, DELTA)

    assert_equal(a, result)
  end

  def test_distance_to
    a = Mittsu::Vector2.new(1.4, -3.4)
    b = Mittsu::Vector2.new(3.7, 4.2)

    assert_in_delta(7.940403012442126, a.distance_to(b), DELTA)
  end

  def test_distance_to_squared
    a = Mittsu::Vector2.new(1.4, -3.4)
    b = Mittsu::Vector2.new(3.7, 4.2)

    assert_in_delta(63.05, a.distance_to_squared(b), DELTA)
  end

  def test_set_length
    a = Mittsu::Vector2.new(1.4, -3.4)

    result = a.set_length 2.3

    assert_in_delta(0.87572455208487, a.x, DELTA)
    assert_in_delta(-2.12675962649186, a.y, DELTA)
    assert_equal(result, a)
  end

  def test_lerp
    alphas = [ -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1 ]
    expected = [ [ 1.17, -4.16 ], [ 1.4, -3.4 ], [ 1.63, -2.64 ], [ 1.86, -1.88 ], [ 2.09, -1.12 ], [ 2.32, -0.36 ],
      [ 2.55, 0.4 ], [ 2.78, 1.16 ], [ 3.01, 1.92 ], [ 3.24, 2.68 ], [ 3.47, 3.44 ], [ 3.7, 4.2 ], [ 3.93, 4.96 ] ]
    alphas.zip(expected).each do |alpha, (exx, exy)|
      a = Mittsu::Vector2.new(1.4, -3.4)
      b = Mittsu::Vector2.new(3.7, 4.2)

      result = a.lerp(b, alpha)

      assert_in_delta(exx, a.x, DELTA)
      assert_in_delta(exy, a.y, DELTA)
      assert_equal a, result
    end
  end

  def test_lerp_vectors
    alphas = [ -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1 ]
    expected = [ [ 1.17, -4.16 ], [ 1.4, -3.4 ], [ 1.63, -2.64 ], [ 1.86, -1.88 ], [ 2.09, -1.12 ], [ 2.32, -0.36 ],
      [ 2.55, 0.4 ], [ 2.78, 1.16 ], [ 3.01, 1.92 ], [ 3.24, 2.68 ], [ 3.47, 3.44 ], [ 3.7, 4.2 ], [ 3.93, 4.96 ] ]
    alphas.zip(expected).each do |alpha, (exx, exy)|
      a = Mittsu::Vector2.new(1.4, -3.4)
      b = Mittsu::Vector2.new(3.7, 4.2)
      c = Mittsu::Vector2.new

      result = c.lerp_vectors(a, b, alpha)

      assert_in_delta(exx, c.x, DELTA)
      assert_in_delta(exy, c.y, DELTA)
      assert_equal c, result
    end
  end

  def test_equality
    a = Mittsu::Vector2.new(1.4, -3.4)
    a2 = Mittsu::Vector2.new(1.4, -3.4)
    b = Mittsu::Vector2.new(3.7, 4.2)

    assert_equal a, a2
    refute_equal a, b
  end

  def test_from_array
    a = Mittsu::Vector2.new

    result = a.from_array([1.2, 2.4])

    assert_equal 1.2, a.x
    assert_equal 2.4, a.y
    assert_equal a, result

    a.from_array([1.2, 2.4, 4.8, 8.16, 16.32], 2)

    assert_equal 4.8, a.x
    assert_equal 8.16, a.y
  end

  def test_to_array
    a = Mittsu::Vector2.new(1.4, -3.4)
    assert_equal [1.4, -3.4], a.to_array

    ary = [0,0]
    a.to_array(ary)
    assert_equal [1.4, -3.4], ary

    ary = [0,0,0,0,0]
    a.to_array(ary, 2)
    assert_equal [0, 0, 1.4, -3.4, 0], ary

    assert_equal [1.4, -3.4], a.to_a
  end

  def test_from_attribute
    a = Mittsu::Vector2.new
    att = Mittsu::BufferAttribute.new([1.0, 2.0, 4.0, 8.0, 16.0], 2)

    result = a.from_attribute(att, 0)
    assert_equal 1.0, a.x
    assert_equal 2.0, a.y
    assert_equal a, result

    a.from_attribute(att, 1)
    assert_equal 4.0, a.x
    assert_equal 8.0, a.y

    att = Mittsu::BufferAttribute.new([1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0], 4)

    a.from_attribute(att, 1)
    assert_equal 16.0, a.x
    assert_equal 32.0, a.y

    a.from_attribute(att, 1, 2)
    assert_equal 64.0, a.x
    assert_equal 128.0, a.y
  end

  def test_clone
    a = Mittsu::Vector2.new(1.4, -3.4)

    b = a.clone

    assert_instance_of Mittsu::Vector2, b
    assert_equal(1.4, b.x)
    assert_equal(-3.4, b.y)
  end
end
