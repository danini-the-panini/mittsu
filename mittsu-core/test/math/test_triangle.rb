require 'minitest_helper'

class TestTriangle < Minitest::Test
  def test_constructor
    a = Mittsu::Triangle.new
    assert_equal(zero3, a.a)
    assert_equal(zero3, a.b)
    assert_equal(zero3, a.c)

    a = Mittsu::Triangle.new(one3.clone.negate, one3.clone, two3.clone)
    assert_equal(one3.clone.negate, a.a)
    assert_equal(one3, a.b)
    assert_equal(two3, a.c)
  end

  def test_copy
    a = Mittsu::Triangle.new(one3.clone.negate, one3.clone, two3.clone)
    b = Mittsu::Triangle.new.copy(a)
    assert_equal(one3.clone.negate, b.a)
    assert_equal(one3, b.b)
    assert_equal(two3, b.c)

    # ensure that it is a true copy
    a.a = one3
    a.b = zero3
    a.c = zero3
    assert_equal(one3.clone.negate, b.a)
    assert_equal(one3, b.b)
    assert_equal(two3, b.c)
  end

  def test_set_from_points_and_indices
    a = Mittsu::Triangle.new

    points = [ one3, one3.clone.negate, two3 ]
    a.set_from_points_and_indices(points, 1, 0, 2)
    assert_equal(one3.clone.negate, a.a)
    assert_equal(one3, a.b)
    assert_equal(two3, a.c)
  end

  def test_set
    a = Mittsu::Triangle.new

    a.set(one3.clone.negate, one3, two3)
    assert_equal(one3.clone.negate, a.a)
    assert_equal(one3, a.b)
    assert_equal(two3, a.c)

  end

  def test_area
    a = Mittsu::Triangle.new

    assert_equal(0, a.area)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert_equal(0.5, a.area)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert_equal(2, a.area)

    # colinear triangle.
    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(3, 0, 0))
    assert_equal(0, a.area)
  end

  def test_midpoint
    a = Mittsu::Triangle.new

    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.midpoint)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert_equal(Mittsu::Vector3.new(1.0/3.0, 1.0/3.0, 0), a.midpoint)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert_equal(Mittsu::Vector3.new(2.0/3.0, 0, 2.0/3.0), a.midpoint)
  end

  def test_normal
    a = Mittsu::Triangle.new

    assert_equal(Mittsu::Vector3.new(0, 0, 0), a.normal)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert_equal(Mittsu::Vector3.new(0, 0, 1), a.normal)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert_equal(Mittsu::Vector3.new(0, 1, 0), a.normal)
  end

  def test_plane
    a = Mittsu::Triangle.new

    # artificial normal is created in this case.
    assert_equal(0, a.plane.distance_to_point(a.a))
    assert_equal(0, a.plane.distance_to_point(a.b))
    assert_equal(0, a.plane.distance_to_point(a.c))
    assert_equal(a.normal, a.plane.normal)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert_equal(0, a.plane.distance_to_point(a.a))
    assert_equal(0, a.plane.distance_to_point(a.b))
    assert_equal(0, a.plane.distance_to_point(a.c))
    assert_equal(a.normal, a.plane.normal)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert_equal(0, a.plane.distance_to_point(a.a))
    assert_equal(0, a.plane.distance_to_point(a.b))
    assert_equal(0, a.plane.distance_to_point(a.c))
    assert_equal(a.normal, a.plane.normal.clone.normalize)
  end

  def test_barycoord_from_point
    a = Mittsu::Triangle.new

    bad = Mittsu::Vector3.new(-2, -1, -1)

    assert_equal(bad, a.barycoord_from_point(a.a))
    assert_equal(bad, a.barycoord_from_point(a.b))
    assert_equal(bad, a.barycoord_from_point(a.c))

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert_equal(Mittsu::Vector3.new(1, 0, 0), a.barycoord_from_point(a.a))
    assert_equal(Mittsu::Vector3.new(0, 1, 0), a.barycoord_from_point(a.b))
    assert_equal(Mittsu::Vector3.new(0, 0, 1), a.barycoord_from_point(a.c))
    assert_in_delta(0, a.barycoord_from_point(a.midpoint).distance_to(Mittsu::Vector3.new(1.0/3.0, 1.0/3.0, 1.0/3.0)), 0.0001)

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert_equal(Mittsu::Vector3.new(1, 0, 0), a.barycoord_from_point(a.a))
    assert_equal(Mittsu::Vector3.new(0, 1, 0), a.barycoord_from_point(a.b))
    assert_equal(Mittsu::Vector3.new(0, 0, 1), a.barycoord_from_point(a.c))
    assert_in_delta(0, a.barycoord_from_point(a.midpoint).distance_to(Mittsu::Vector3.new(1.0/3.0, 1.0/3.0, 1.0/3.0)), 0.0001, "Passed!")
  end

  def test_contains_point
    a = Mittsu::Triangle.new

    refute(a.contains_point?(a.a))
    refute(a.contains_point?(a.b))
    refute(a.contains_point?(a.c))

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0))
    assert(a.contains_point?(a.a))
    assert(a.contains_point?(a.b))
    assert(a.contains_point?(a.c))
    assert(a.contains_point?(a.midpoint))
    refute(a.contains_point?(Mittsu::Vector3.new(-1, -1, -1)))

    a = Mittsu::Triangle.new(Mittsu::Vector3.new(2, 0, 0), Mittsu::Vector3.new(0, 0, 0), Mittsu::Vector3.new(0, 0, 2))
    assert(a.contains_point?(a.a))
    assert(a.contains_point?(a.b))
    assert(a.contains_point?(a.c))
    assert(a.contains_point?(a.midpoint))
    refute(a.contains_point?(Mittsu::Vector3.new(-1, -1, -1)))
  end
end
