require 'minitest_helper'

class TestBox3 < Minitest::Test
  def compare_box(a, b, threshold = 0.0001)
    a.min.distanceTo(b.min) < threshold && a.max.distanceTo(b.max) < threshold
  end

  def assert_box_equal3(a, b, threshold = 0.0001)
    assert(compare_box(a, b, threshold), "#{a} does not equal #{b}")
  end

  def refute_box_equal3(a, b, threshold = 0.0001)
    refute(compare_box(a, b, threshold), "#{a} equals #{b}")
  end

  def test_constructor
    a = Mittsu::Box3.new
    assert_equal(posInf3, a.min)
    assert_equal(negInf3, a.max)

    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    assert_equal(zero3, a.min)
    assert_equal(zero3, a.max)

    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    assert_equal(zero3, a.min)
    assert_equal(one3, a.max)
  end

  def test_copy
    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    b = Mittsu::Box3.new.copy(a)
    assert_equal(zero3, b.min)
    assert_equal(one3, b.max)

    # ensure that it is a true copy
    a.min = zero3
    a.max = one3
    assert_equal(zero3, b.min)
    assert_equal(one3, b.max)
  end

  def test_set
    a = Mittsu::Box3.new

    a.set(zero3, one3)
    assert_equal(zero3, a.min)
    assert_equal(one3, a.max)
  end

  def test_set_from_points
    a = Mittsu::Box3.new

    a.set_from_points([ zero3, one3, two3 ])
    assert_equal(zero3, a.min)
    assert_equal(two3, a.max)

    a.set_from_points([ one3 ])
    assert_equal(one3, a.min)
    assert_equal(one3, a.max)

    a.set_from_points([])
    assert(a.empty?)
  end

  def test_empty_make_empty
    a = Mittsu::Box3.new

    assert(a.empty?)

    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    refute(a.empty?)

    a.make_empty
    assert(a.empty?)
  end

  def test_center
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    assert_equal(zero3, a.center)

    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    midpoint = one3.clone.multiply_scalar(0.5)
    assert_equal(midpoint, a.center)
  end

  def test_size
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    assert_equal(zero3, a.size)

    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    assert_equal(one3, a.size)
  end

  def test_expand_by_point
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    a.expand_by_point(zero3)
    assert_equal(zero3, a.size)

    a.expand_by_point(one3)
    assert_equal(one3, a.size)

    a.expand_by_point(one3.clone.negate)
    assert_equal(one3.clone.multiply_scalar(2), a.size)
    assert_equal(zero3, a.center)
  end

  def test_expand_by_vector
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    a.expand_by_vector(zero3)
    assert_equal(zero3, a.size)

    a.expand_by_vector(one3)
    assert_equal(one3.clone.multiply_scalar(2), a.size)
    assert_equal(zero3, a.center)
  end

  def test_expand_by_scalar
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    a.expand_by_scalar(0)
    assert_equal(zero3, a.size)

    a.expand_by_scalar(1)
    assert_equal(one3.clone.multiply_scalar(2), a.size)
    assert_equal(zero3, a.center)
  end

  def test_contains_point
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)

    assert(a.contains_point?(zero3))
    refute(a.contains_point?(one3))

    a.expand_by_scalar(1)
    assert(a.contains_point?(zero3))
    assert(a.contains_point?(one3))
    assert(a.contains_point?(one3.clone.negate))
  end

  def test_contains_box
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert(a.contains_box?(a))
    refute(a.contains_box?(b))
    refute(a.contains_box?(c))

    assert(b.contains_box?(a))
    assert(c.contains_box?(a))
    refute(b.contains_box?(c))
  end

  def test_get_parameter
    a = Mittsu::Box3.new(zero3.clone, one3.clone)
    b = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.parameter(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Mittsu::Vector3.new(1, 1, 1), a.parameter(Mittsu::Vector3.new(1, 1, 1)))

    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.parameter(Mittsu::Vector3.new(-1, -1, -1)))
    assert_equal(Mittsu::Vector3.new(0.5, 0.5, 0.5), b.parameter(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Mittsu::Vector3.new(1, 1, 1), b.parameter(Mittsu::Vector3.new(1, 1, 1)))
  end

  def test_clamp_point
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.clamp_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.clamp_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.clamp_point(Mittsu::Vector3.new(-1, -1, -1)))

    assert_equal(Mittsu::Vector3.new(1, 1, 1), b.clamp_point(Mittsu::Vector3.new(2, 2, 2)))
    assert_equal(Mittsu::Vector3.new(1, 1, 1), b.clamp_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.clamp_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Mittsu::Vector3.new(-1, -1, -1), b.clamp_point(Mittsu::Vector3.new(-1, -1, -1)))
    assert_equal(Mittsu::Vector3.new(-1, -1, -1), b.clamp_point(Mittsu::Vector3.new(-2, -2, -2)))
  end

  def test_distance_to_point
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(0, a.distance_to_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Math.sqrt(3), a.distance_to_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(Math.sqrt(3), a.distance_to_point(Mittsu::Vector3.new(-1, -1, -1)))

    assert_equal(Math.sqrt(3), b.distance_to_point(Mittsu::Vector3.new(2, 2, 2)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(-1, -1, -1)))
    assert_equal(Math.sqrt(3), b.distance_to_point(Mittsu::Vector3.new(-2, -2, -2)))
  end

  def test_distance_to_point
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(0, a.distance_to_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(Math.sqrt(3), a.distance_to_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(Math.sqrt(3), a.distance_to_point(Mittsu::Vector3.new(-1, -1, -1)))

    assert_equal(Math.sqrt(3), b.distance_to_point(Mittsu::Vector3.new(2, 2, 2)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(1, 1, 1)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(0, 0, 0)))
    assert_equal(0, b.distance_to_point(Mittsu::Vector3.new(-1, -1, -1)))
    assert_equal(Math.sqrt(3), b.distance_to_point(Mittsu::Vector3.new(-2, -2, -2)))
  end

  def test_is_intersection_box
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert(a.intersection_box?(a))
    assert(a.intersection_box?(b))
    assert(a.intersection_box?(c))

    assert(b.intersection_box?(a))
    assert(c.intersection_box?(a))
    assert(b.intersection_box?(c))

    b.translate(Mittsu::Vector3.new(2, 2, 2))
    refute(a.intersection_box?(b))
    refute(b.intersection_box?(a))
    refute(b.intersection_box?(c))
  end

  def test_get_bounding_sphere
    skip
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(Mittsu::Sphere.new(zero3, 0), a.bounding_sphere)
    assert_equal(Mittsu::Sphere(one3.clone.multiply_scalar(0.5), math.sqrt(3) * 0.5), b.bounding_sphere)
    assert_equal(Mittsu::Sphere.new(zero3, Math.sqrt(12) * 0.5), c.bounding_sphere)
  end

  def test_intersect
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(a, a.clone.intersect(a))
    assert_equal(a, a.clone.intersect(b))
    assert_equal(b, b.clone.intersect(b))
    assert_equal(a, a.clone.intersect(c))
    assert_equal(b, b.clone.intersect(c))
    assert_equal(c, c.clone.intersect(c))
  end

  def test_union
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)

    assert_equal(a, a.clone.union(a))
    assert_equal(b, a.clone.union(b))
    assert_equal(c, a.clone.union(c))
    assert_equal(c, b.clone.union(c))
  end

  def compare_box(a, b, threshold)
    threshold = threshold || 0.0001
    a.min.distance_to(b.min) < threshold &&
      a.max.distance_to(b.max) < threshold
  end

  def test_apply_matrix4
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    c = Mittsu::Box3.new(one3.clone.negate, one3.clone)
    d = Mittsu::Box3.new(one3.clone.negate, zero3.clone)

    m = Mittsu::Matrix4.new.make_translation(1, -2, 1)
    t1 = Mittsu::Vector3.new(1, -2, 1)

    assert_box_equal3(a.clone.apply_matrix4(m), a.clone.translate(t1))
    assert_box_equal3(b.clone.apply_matrix4(m), b.clone.translate(t1))
    assert_box_equal3(c.clone.apply_matrix4(m), c.clone.translate(t1))
    assert_box_equal3(d.clone.apply_matrix4(m), d.clone.translate(t1))
  end

  def test_translate
    a = Mittsu::Box3.new(zero3.clone, zero3.clone)
    b = Mittsu::Box3.new(zero3.clone, one3.clone)
    # c = Mittsu::Box3.new(one3.clone.negate, one3.clone)
    d = Mittsu::Box3.new(one3.clone.negate, zero3.clone)

    assert_equal(Mittsu::Box3.new(one3, one3), a.clone.translate(one3))
    assert_equal(a, a.clone.translate(one3).translate(one3.clone.negate))
    assert_equal(b, d.clone.translate(one3))
    assert_equal(d, b.clone.translate(one3.clone.negate))
  end
end
