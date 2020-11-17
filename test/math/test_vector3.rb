require 'minitest_helper'

class TestVector3 < Minitest::Test

  def test_initialize
    a = Mittsu::Vector3.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)

    a = Mittsu::Vector3.new(x, y, z)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
  end

  def test_copy
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new.copy(a)
    assert_equal(x, b.x)
    assert_equal(y, b.y)
    assert_equal(z, b.z)

    # ensure that it is a true copy
    a.x = 0
    a.y = -1
    a.z = -2
    assert_equal(x, b.x)
    assert_equal(y, b.y)
    assert_equal(z, b.z)
  end

  def test_set
    a = Mittsu::Vector3.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)

    a.set(x, y, z)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
  end

  def test_setters
    a = Mittsu::Vector3.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)

    a.x = x
    a.y = y
    a.z = z

    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
  end

  def test_subscript
    a = Mittsu::Vector3.new
    assert_equal(0, a[0])
    assert_equal(0, a[1])
    assert_equal(0, a[2])
    assert_raises(IndexError) { a[-1]}
    assert_raises(IndexError) { a[3]}

    a[0] = 1
    a[1] = 2
    a[2] = 3
    assert_raises(IndexError) { a[-1] = 0}
    assert_raises(IndexError) { a[3] = 4}

    assert_equal(1, a[0])
    assert_equal(2, a[1])
    assert_equal(3, a[2])
    assert_raises(IndexError) { a[-1]}
    assert_raises(IndexError) { a[3]}
  end

  def test_add
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new(-x, -y, -z)

    a.add(b)
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)

    c = Mittsu::Vector3.new.add_vectors(b, b)
    assert_equal(-2*x, c.x)
    assert_equal(-2*y, c.y)
    assert_equal(-2*z, c.z)
  end

  def test_sub
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new(-x, -y, -z)

    a.sub(b)
    assert_equal(2*x, a.x)
    assert_equal(2*y, a.y)
    assert_equal(2*z, a.z)

    c = Mittsu::Vector3.new.sub_vectors(a, a)
    assert_equal(0, c.x)
    assert_equal(0, c.y)
    assert_equal(0, c.z)
  end

  def test_multiply_divide
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new(-x, -y, -z)

    a.multiply_scalar(-2)
    assert_equal(x*-2, a.x)
    assert_equal(y*-2, a.y)
    assert_equal(z*-2, a.z)

    b.multiply_scalar(-2)
    assert_equal(2*x, b.x)
    assert_equal(2*y, b.y)
    assert_equal(2*z, b.z)

    a.divide_scalar(-2)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)

    b.divide_scalar(-2)
    assert_equal(-x, b.x)
    assert_equal(-y, b.y)
    assert_equal(-z, b.z)
  end

  def test_min_max_clamp
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new(-x, -y, -z)
    c = Mittsu::Vector3.new

    c.copy(a).min(b)
    assert_equal(-x, c.x)
    assert_equal(-y, c.y)
    assert_equal(-z, c.z)

    c.copy(a).max(b)
    assert_equal(x, c.x)
    assert_equal(y, c.y)
    assert_equal(z, c.z)

    c.set(-2*x, 2*y, -2*z)
    c.clamp(b, a)
    assert_equal(-x, c.x)
    assert_equal(y, c.y)
    assert_equal(-z, c.z)
  end

  def test_negate
    a = Mittsu::Vector3.new(x, y, z)

    a.negate
    assert_equal(-x, a.x)
    assert_equal(-y, a.y)
    assert_equal(-z, a.z)
  end

  def test_dot
    a = Mittsu::Vector3.new(x, y, z)
    b = Mittsu::Vector3.new(-x, -y, -z)
    c = Mittsu::Vector3.new

    result = a.dot(b)
    assert_equal((-x*x-y*y-z*z), result)

    result = a.dot(c)
    assert_equal(0, result)
  end

  def test_length_length_sq
    a = Mittsu::Vector3.new(x, 0, 0)
    b = Mittsu::Vector3.new(0, -y, 0)
    c = Mittsu::Vector3.new(0, 0, z)
    d = Mittsu::Vector3.new

    assert_equal(x, a.length)
    assert_equal(x*x, a.length_sq)
    assert_equal(y, b.length)
    assert_equal(y*y, b.length_sq)
    assert_equal(z, c.length)
    assert_equal(z*z, c.length_sq)
    assert_equal(0, d.length)
    assert_equal(0, d.length_sq)

    a.set(x, y, z)
    assert_equal(::Math.sqrt(x*x + y*y + z*z), a.length)
    assert_equal((x*x + y*y + z*z), a.length_sq)
  end

  def test_normalize
    a = Mittsu::Vector3.new(x, 0, 0)
    b = Mittsu::Vector3.new(0, -y, 0)
    c = Mittsu::Vector3.new(0, 0, z)

    a.normalize
    assert_in_delta(1, a.length, DELTA)
    assert_in_delta(1, a.x, DELTA)

    b.normalize
    assert_in_delta(1, b.length, DELTA)
    assert_in_delta(-1, b.y, DELTA)

    c.normalize
    assert_in_delta(1, c.length, DELTA)
    assert_in_delta(1, c.z, DELTA)
  end

  def test_distance_to_distance_to_squared
    a = Mittsu::Vector3.new(x, 0, 0)
    b = Mittsu::Vector3.new(0, -y, 0)
    c = Mittsu::Vector3.new(0, 0, z)
    d = Mittsu::Vector3.new

    assert_equal(x, a.distance_to(d))
    assert_equal(x*x, a.distance_to_squared(d))

    assert_equal(y, b.distance_to(d))
    assert_equal(y*y, b.distance_to_squared(d))

    assert_equal(z, c.distance_to(d))
    assert_equal(z*z, c.distance_to_squared(d))
  end

  def test_set_length
    a = Mittsu::Vector3.new(x, 0, 0)

    assert_in_delta(x, a.length, DELTA)
    a.set_length(y)
    assert_in_delta(y, a.length, DELTA)

    a = Mittsu::Vector3.new(0, 0, 0)
    assert_equal(0, a.length)
    a.set_length(y)
    assert_equal(0, a.length)

  end

  def test_project_on_vector
    a = Mittsu::Vector3.new(1, 0, 0)
    b = Mittsu::Vector3.new
    normal = Mittsu::Vector3.new(10, 0, 0)

    assert_equal(Mittsu::Vector3.new(1, 0, 0), b.copy(a).project_on_vector(normal))

    a.set(0, 1, 0)
    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.copy(a).project_on_vector(normal))

    a.set(0, 0, -1)
    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.copy(a).project_on_vector(normal))

    a.set(-1, 0, 0)
    assert_equal(Mittsu::Vector3.new(-1, 0, 0), b.copy(a).project_on_vector(normal))
  end

  def test_project_on_plane
    a = Mittsu::Vector3.new(1, 0, 0)
    b = Mittsu::Vector3.new
    normal = Mittsu::Vector3.new(1, 0, 0)

    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.copy(a).project_on_plane(normal))

    a.set(0, 1, 0)
    assert_equal(Mittsu::Vector3.new(0, 1, 0), b.copy(a).project_on_plane(normal))

    a.set(0, 0, -1)
    assert_equal(Mittsu::Vector3.new(0, 0, -1), b.copy(a).project_on_plane(normal))

    a.set(-1, 0, 0)
    assert_equal(Mittsu::Vector3.new(0, 0, 0), b.copy(a).project_on_plane(normal))

  end

  def test_reflect
    a = Mittsu::Vector3.new
    normal = Mittsu::Vector3.new(0, 1, 0)
    b = Mittsu::Vector3.new

    a.set(0, -1, 0)
    assert_equal(Mittsu::Vector3.new(0, 1, 0), b.copy(a).reflect(normal))

    a.set(1, -1, 0)
    assert_equal(Mittsu::Vector3.new(1, 1, 0), b.copy(a).reflect(normal))

    a.set(1, -1, 0)
    normal.set(0, -1, 0)
    assert_equal(Mittsu::Vector3.new(1, 1, 0), b.copy(a).reflect(normal))
  end

  def test_angle_to
    a = Mittsu::Vector3.new(0, -0.18851655680720186, 0.9820700116639124)
    b = Mittsu::Vector3.new(0, 0.18851655680720186, -0.9820700116639124)

    assert_in_delta(a.angle_to(a), 0)
    assert_in_delta(a.angle_to(b), ::Math::PI)

    x = Mittsu::Vector3.new(1, 0, 0)
    y = Mittsu::Vector3.new(0, 1, 0)
    z = Mittsu::Vector3.new(0, 0, 1)

    assert_equal(x.angle_to(y), ::Math::PI / 2)
    assert_equal(x.angle_to(z), ::Math::PI / 2)
    assert_equal(z.angle_to(x), ::Math::PI / 2)

    assert_in_delta(::Math::PI / 4, x.angle_to(Mittsu::Vector3.new(1, 1, 0)), DELTA)
  end

  def test_lerp_clone
    a = Mittsu::Vector3.new(x, 0, z)
    b = Mittsu::Vector3.new(0, -y, 0)

    assert_equal(a.lerp(a, 0.5), a.lerp(a, 0))
    assert_equal(a.lerp(a, 1), a.lerp(a, 0))

    assert_equal(a, a.clone.lerp(b, 0))

    assert_equal(x*0.5, a.clone.lerp(b, 0.5).x)
    assert_equal(-y*0.5, a.clone.lerp(b, 0.5).y)
    assert_equal(z*0.5, a.clone.lerp(b, 0.5).z)

    assert_equal(b, a.clone.lerp(b, 1))
  end

  def test_equals
    a = Mittsu::Vector3.new(x, 0, z)
    b = Mittsu::Vector3.new(0, -y, 0)

    refute_equal(b.x, a.x)
    refute_equal(b.y, a.y)
    refute_equal(b.z, a.z)

    refute_equal(b, a)
    refute_equal(a, b)

    a.copy(b)
    assert_equal(b.x, a.x)
    assert_equal(b.y, a.y)
    assert_equal(b.z, a.z)

    assert_equal(b, a)
    assert_equal(a, b)
  end
end
