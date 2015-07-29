require 'minitest_helper'

class TestFrustum < Minitest::Test
  UNIT3 = Mittsu::Vector3.new(1, 0, 0)

  def plane_equals(a, b, tolerance = 0.0001)
    return false if a.normal.distance_to(b.normal) > tolerance
    return false if (a.constant - b.constant).abs > tolerance
    true
  end

  def assert_plane_equals(a, b, tolerance = 0.0001)
    assert(plane_equals(a, b, tolerance), "#{a} does not equal #{b}")
  end

  def refute_plane_equals(a, b, tolerance = 0.0001)
    refute(plane_equals(a, b, tolerance), "#{a} equals #{b}")
  end

  def test_constructor
    a = Mittsu::Frustum.new

    refute_equal(nil, a.planes)
    assert_equal(6, a.planes.length)

    p_default = Mittsu::Plane.new
    6.times do |i|
      assert_equal(p_default, a.planes[i])
    end

    p0 = Mittsu::Plane.new(UNIT3, -1)
    p1 = Mittsu::Plane.new(UNIT3, 1)
    p2 = Mittsu::Plane.new(UNIT3, 2)
    p3 = Mittsu::Plane.new(UNIT3, 3)
    p4 = Mittsu::Plane.new(UNIT3, 4)
    p5 = Mittsu::Plane.new(UNIT3, 5)

    a = Mittsu::Frustum.new(p0, p1, p2, p3, p4, p5)
    assert_equal(p0, a.planes[0])
    assert_equal(p1, a.planes[1])
    assert_equal(p2, a.planes[2])
    assert_equal(p3, a.planes[3])
    assert_equal(p4, a.planes[4])
    assert_equal(p5, a.planes[5])
  end

  def test_copy
    p0 = Mittsu::Plane.new(UNIT3, -1)
    p1 = Mittsu::Plane.new(UNIT3, 1)
    p2 = Mittsu::Plane.new(UNIT3, 2)
    p3 = Mittsu::Plane.new(UNIT3, 3)
    p4 = Mittsu::Plane.new(UNIT3, 4)
    p5 = Mittsu::Plane.new(UNIT3, 5)

    b = Mittsu::Frustum.new(p0, p1, p2, p3, p4, p5)
    a = Mittsu::Frustum.new.copy(b)
    assert_equal(p0, a.planes[0])
    assert_equal(p1, a.planes[1])
    assert_equal(p2, a.planes[2])
    assert_equal(p3, a.planes[3])
    assert_equal(p4, a.planes[4])
    assert_equal(p5, a.planes[5])

    # ensure it is a true copy by modifying source
    b.planes[0] = p1
    assert_equal(p0, a.planes[0])
  end

  def test_set_from_matrix_make_orthographic_contains_point
    m = Mittsu::Matrix4.new.make_orthographic(-1, 1, -1, 1, 1, 100)
    a = Mittsu::Frustum.new.set_from_matrix(m)

    refute(a.contains_point?(Mittsu::Vector3.new(0, 0, 0)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -50)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(-1, -1, -1.001)))
    refute(a.contains_point?(Mittsu::Vector3.new(-1.1, -1.1, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(1, 1, -1.001)))
    refute(a.contains_point?(Mittsu::Vector3.new(1.1, 1.1, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -99.999)))
    assert(a.contains_point?(Mittsu::Vector3.new(-1, -1, -99.999)))
    refute(a.contains_point?(Mittsu::Vector3.new(-1.1, -1.1, -100.1)))
    assert(a.contains_point?(Mittsu::Vector3.new(1, 1, -99.999)))
    refute(a.contains_point?(Mittsu::Vector3.new(1.1, 1.1, -100.1)))
    refute(a.contains_point?(Mittsu::Vector3.new(0, 0, -101)))
  end

  def test_set_from_matrix_make_frustum_contains_point
    m = Mittsu::Matrix4.new.make_frustum(-1, 1, -1, 1, 1, 100)
    a = Mittsu::Frustum.new.set_from_matrix(m)

    refute(a.contains_point?(Mittsu::Vector3.new(0, 0, 0)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -50)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(-1, -1, -1.001)))
    refute(a.contains_point?(Mittsu::Vector3.new(-1.1, -1.1, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(1, 1, -1.001)))
    refute(a.contains_point?(Mittsu::Vector3.new(1.1, 1.1, -1.001)))
    assert(a.contains_point?(Mittsu::Vector3.new(0, 0, -99.999)))
    assert(a.contains_point?(Mittsu::Vector3.new(-99.999, -99.999, -99.999)))
    refute(a.contains_point?(Mittsu::Vector3.new(-100.1, -100.1, -100.1)))
    assert(a.contains_point?(Mittsu::Vector3.new(99.999, 99.999, -99.999)))
    refute(a.contains_point?(Mittsu::Vector3.new(100.1, 100.1, -100.1)))
    refute(a.contains_point?(Mittsu::Vector3.new(0, 0, -101)))
  end

  def test_set_from_matrix_make_frustum_intersects_sphere
    m = Mittsu::Matrix4.new.make_frustum(-1, 1, -1, 1, 1, 100)
    a = Mittsu::Frustum.new.set_from_matrix(m)

    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, 0), 0)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, 0), 0.9)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, 0), 1.1)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, -50), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, -1.001), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-1, -1, -1.001), 0)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-1.1, -1.1, -1.001), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-1.1, -1.1, -1.001), 0.5)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(1, 1, -1.001), 0)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(1.1, 1.1, -1.001), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(1.1, 1.1, -1.001), 0.5)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, -99.999), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-99.999, -99.999, -99.999), 0)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-100.1, -100.1, -100.1), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(-100.1, -100.1, -100.1), 0.5)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(99.999, 99.999, -99.999), 0)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(100.1, 100.1, -100.1), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(100.1, 100.1, -100.1), 0.2)))
    refute(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, -101), 0)))
    assert(a.intersects_sphere?(Mittsu::Sphere.new(Mittsu::Vector3.new(0, 0, -101), 1.1)))
  end

  def test_clone
    p0 = Mittsu::Plane.new(UNIT3, -1)
    p1 = Mittsu::Plane.new(UNIT3, 1)
    p2 = Mittsu::Plane.new(UNIT3, 2)
    p3 = Mittsu::Plane.new(UNIT3, 3)
    p4 = Mittsu::Plane.new(UNIT3, 4)
    p5 = Mittsu::Plane.new(UNIT3, 5)

    b = Mittsu::Frustum.new(p0, p1, p2, p3, p4, p5)
    a = b.clone
    assert_equal(p0, a.planes[0])
    assert_equal(p1, a.planes[1])
    assert_equal(p2, a.planes[2])
    assert_equal(p3, a.planes[3])
    assert_equal(p4, a.planes[4])
    assert_equal(p5, a.planes[5])

    # ensure it is a true copy by modifying source
    a.planes[0].copy(p1)
    assert_equal(p0, b.planes[0])
  end
end
