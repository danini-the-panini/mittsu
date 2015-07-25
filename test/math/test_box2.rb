require 'minitest_helper'

class TestBox2 < Minitest::Test

  def test_constructor
    a = Mittsu::Box2.new
    assert_equal(posInf2, a.min)
    assert_equal(negInf2, a.max)

    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    assert_equal(zero2, a.min)
    assert_equal(zero2, a.max)

    a = Mittsu::Box2.new(zero2.clone, one2.clone)
    assert_equal(zero2, a.min)
    assert_equal(one2, a.max)
  end

  def test_copy
    a = Mittsu::Box2.new(zero2.clone, one2.clone)
    b = Mittsu::Box2.new.copy(a)
    assert_equal(zero2, b.min)
    assert_equal(one2, b.max)

    # ensure that it is a true copy
    a.min = zero2
    a.max = one2
    assert_equal(zero2, b.min)
    assert_equal(one2, b.max)
  end

  def test_set
    a = Mittsu::Box2.new

    a.set(zero2, one2)
    assert_equal(zero2, a.min)
    assert_equal(one2, a.max)
  end

  def test_set_from_points
    a = Mittsu::Box2.new

    a.set_from_points([ zero2, one2, two2 ])
    assert_equal(zero2, a.min)
    assert_equal(two2, a.max)

    a.set_from_points([ one2 ])
    assert_equal(one2, a.min)
    assert_equal(one2, a.max)

    a.set_from_points([])
    assert(a.empty?)
  end

  def test_empty_make_empty
    a = Mittsu::Box2.new

    assert(a.empty?)

    a = Mittsu::Box2.new(zero2.clone, one2.clone)
    refute(a.empty?)

    a.make_empty
    assert(a.empty?)
  end

  def test_center
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    assert_equal(zero2, a.center)

    a = Mittsu::Box2.new(zero2, one2)
    midpoint = one2.clone.multiply_scalar(0.5)
    assert_equal(midpoint, a.center)
  end

  def test_size
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    assert_equal(zero2, a.size)

    a = Mittsu::Box2.new(zero2.clone, one2.clone)
    assert_equal(one2, a.size)
  end

  def test_expand_by_point
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    a.expand_by_point(zero2)
    assert_equal(zero2, a.size)

    a.expand_by_point(one2)
    assert_equal(one2, a.size)

    a.expand_by_point(one2.clone.negate)
    assert_equal(one2.clone.multiply_scalar(2), a.size)
    assert_equal(zero2, a.center)
  end

  def test_expand_by_vector
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    a.expand_by_vector(zero2)
    assert_equal(zero2, a.size)

    a.expand_by_vector(one2)
    assert_equal(one2.clone.multiply_scalar(2), a.size)
    assert_equal(zero2, a.center)
  end

  def test_expand_by_scalar
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    a.expand_by_scalar(0)
    assert_equal(zero2, a.size)

    a.expand_by_scalar(1)
    assert_equal(one2.clone.multiply_scalar(2), a.size)
    assert_equal(zero2, a.center)
  end

  def test_contains_point
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)

    assert(a.contains_point?(zero2))
    refute(a.contains_point?(one2))

    a.expand_by_scalar(1)
    assert(a.contains_point?(zero2))
    assert(a.contains_point?(one2))
    assert(a.contains_point?(one2.clone.negate))
  end

  def test_contains_box
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(zero2.clone, one2.clone)
    c = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert(a.contains_box?(a))
    refute(a.contains_box?(b))
    refute(a.contains_box?(c))

    assert(b.contains_box?(a))
    assert(c.contains_box?(a))
    refute(b.contains_box?(c))
  end

  def test_get_parameter
    a = Mittsu::Box2.new(zero2.clone, one2.clone)
    b = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert_equal(Mittsu::Vector2.new(0, 0), a.parameter(Mittsu::Vector2.new(0, 0)))
    assert_equal(Mittsu::Vector2.new(1, 1), a.parameter(Mittsu::Vector2.new(1, 1)))

    assert_equal(Mittsu::Vector2.new(0, 0), b.parameter(Mittsu::Vector2.new(-1, -1)))
    assert_equal(Mittsu::Vector2.new(0.5, 0.5), b.parameter(Mittsu::Vector2.new(0, 0)))
    assert_equal(Mittsu::Vector2.new(1, 1), b.parameter(Mittsu::Vector2.new(1, 1)))
  end

  def test_clamp_point
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert_equal(Mittsu::Vector2.new(0, 0), a.clamp_point(Mittsu::Vector2.new(0, 0)))
    assert_equal(Mittsu::Vector2.new(0, 0), a.clamp_point(Mittsu::Vector2.new(1, 1)))
    assert_equal(Mittsu::Vector2.new(0, 0), a.clamp_point(Mittsu::Vector2.new(-1, -1)))

    assert_equal(Mittsu::Vector2.new(1, 1), b.clamp_point(Mittsu::Vector2.new(2, 2)))
    assert_equal(Mittsu::Vector2.new(1, 1), b.clamp_point(Mittsu::Vector2.new(1, 1)))
    assert_equal(Mittsu::Vector2.new(0, 0), b.clamp_point(Mittsu::Vector2.new(0, 0)))
    assert_equal(Mittsu::Vector2.new(-1, -1), b.clamp_point(Mittsu::Vector2.new(-1, -1)))
    assert_equal(Mittsu::Vector2.new(-1, -1), b.clamp_point(Mittsu::Vector2.new(-2, -2)))
  end

  def test_distance_to_point
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert_equal(0, a.distance_to_point(Mittsu::Vector2.new(0, 0)))
    assert_equal(Math.sqrt(2), a.distance_to_point(Mittsu::Vector2.new(1, 1)))
    assert_equal(Math.sqrt(2), a.distance_to_point(Mittsu::Vector2.new(-1, -1)))

    assert_equal(Math.sqrt(2), b.distance_to_point(Mittsu::Vector2.new(2, 2)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector2.new(1, 1)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector2.new(0, 0)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector2.new(-1, -1)))
    assert_equal(Math.sqrt(2), b.distance_to_point(Mittsu::Vector2.new(-2, -2)))
  end

  def test_is_intersection_box
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(zero2.clone, one2.clone)
    c = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert(a.intersection_box?(a), "Between a and a")
    assert(a.intersection_box?(b), "Between a and b")
    assert(a.intersection_box?(c), "Between a and c")

    assert(b.intersection_box?(a), "Between b and a")
    assert(c.intersection_box?(a), "Between c and a")
    assert(b.intersection_box?(c), "Between b and c")

    b.translate(Mittsu::Vector2.new(2, 2))
    refute(a.intersection_box?(b), "Between a and b")
    refute(b.intersection_box?(a), "Between b and a")
    refute(b.intersection_box?(c), "Between b and c")
  end

  def test_intersect
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(zero2.clone, one2.clone)
    c = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert_equal(a, a.clone.intersect(a))
    assert_equal(a, a.clone.intersect(b))
    assert_equal(b, b.clone.intersect(b))
    assert_equal(a, a.clone.intersect(c))
    assert_equal(b, b.clone.intersect(c))
    assert_equal(c, c.clone.intersect(c))
  end

  def test_union
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(zero2.clone, one2.clone)
    c = Mittsu::Box2.new(one2.clone.negate, one2.clone)

    assert_equal(a, a.clone.union(a))
    assert_equal(b, a.clone.union(b))
    assert_equal(c, a.clone.union(c))
    assert_equal(c, b.clone.union(c))
  end

  def test_translate
    a = Mittsu::Box2.new(zero2.clone, zero2.clone)
    b = Mittsu::Box2.new(zero2.clone, one2.clone)
  	c = Mittsu::Box2.new(one2.clone.negate, zero2.clone)

    assert_equal(Mittsu::Box2.new(one2, one2), a.clone.translate(one2))
    assert_equal(a, a.clone.translate(one2).translate(one2.clone.negate))
    assert_equal(b, c.clone.translate(one2))
    assert_equal(c, b.clone.translate(one2.clone.negate))
  end
end
