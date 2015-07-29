require 'minitest_helper'

class TestLine3 < Minitest::Test

  def test_constructor_equals
    a = Mittsu::Line3.new
    assert_equal(zero3, a.start_point)
    assert_equal(zero3, a.end_point)

    a = Mittsu::Line3.new(two3.clone, one3.clone)
    assert_equal(two3, a.start_point)
    assert_equal(one3, a.end_point)
  end

  def test_copy_equals
    a = Mittsu::Line3.new(zero3.clone, one3.clone)
    b = Mittsu::Line3.new.copy(a)
    assert_equal(zero3, b.start_point)
    assert_equal(one3, b.end_point)

    # ensure that it is a true copy
    a.start_point = zero3
    a.end_point = one3
    assert_equal(zero3, b.start_point)
    assert_equal(one3, b.end_point)
  end

  def test_set
    a = Mittsu::Line3.new

    a.set(one3, one3)
    assert_equal(one3, a.start_point)
    assert_equal(one3, a.end_point)
  end

  def test_at
    a = Mittsu::Line3.new(one3.clone, Mittsu::Vector3.new(1, 1, 2))

    assert_in_delta(a.at(-1).distance_to(Mittsu::Vector3.new(1, 1, 0)), 0.0001)
    assert(a.at(0).distance_to(one3.clone) < 0.0001)
    assert_in_delta(a.at(1).distance_to(Mittsu::Vector3.new(1, 1, 2)), 0.0001)
    assert_in_delta(a.at(2).distance_to(Mittsu::Vector3.new(1, 1, 3)), 0.0001)
  end

  def test_closest_point_to_point_closest_point_to_point_parameter
    a = Mittsu::Line3.new(one3.clone, Mittsu::Vector3.new(1, 1, 2))

    # nearby the ray
    assert_equal(0, a.closest_point_to_point_parameter(zero3.clone, true))
    b1 = a.closest_point_to_point(zero3.clone, true)
    assert_in_delta(b1.distance_to(Mittsu::Vector3.new(1, 1, 1)), 0.0001)

    # nearby the ray
    assert_equal(-1, a.closest_point_to_point_parameter(zero3.clone, false))
    b2 = a.closest_point_to_point(zero3.clone, false)
    assert_in_delta(b2.distance_to(Mittsu::Vector3.new(1, 1, 0)), 0.0001)

    # nearby the ray
    assert_equal(1, a.closest_point_to_point_parameter(Mittsu::Vector3.new(1, 1, 5), true))
    b = a.closest_point_to_point(Mittsu::Vector3.new(1, 1, 5), true)
    assert_in_delta(b.distance_to(Mittsu::Vector3.new(1, 1, 2)), 0.0001)

    # exactly on the ray
    assert_equal(0, a.closest_point_to_point_parameter(one3.clone, true))
    c = a.closest_point_to_point(one3.clone, true)
    assert(c.distance_to(one3.clone) < 0.0001)
  end
end
