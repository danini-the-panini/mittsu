require 'minitest_helper'

class TestVector4 < Minitest::Test

  def test_constructor
    a = Mittsu::Vector4.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(1, a.w)

    a = Mittsu::Vector4.new(x, y, z, w)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
    assert_equal(w, a.w)
  end

  def test_copy
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new.copy(a)
    assert_equal(x, b.x)
    assert_equal(y, b.y)
    assert_equal(z, b.z)
    assert_equal(w, b.w)

    # ensure that it is a true copy
    a.x = 0
    a.y = -1
    a.z = -2
    a.w = -3
    assert_equal(x, b.x)
    assert_equal(y, b.y)
    assert_equal(z, b.z)
    assert_equal(w, b.w)
  end

  def test_set
    a = Mittsu::Vector4.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(1, a.w)

    a.set(x, y, z, w)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
    assert_equal(w, a.w)
  end

  def test_set_x_set_y_set_z_set_w
    a = Mittsu::Vector4.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(1, a.w)

    a.set_x(x)
    a.set_y(y)
    a.set_z(z)
    a.set_w(w)

    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
    assert_equal(w, a.w)
  end

  def test_set_component_get_component
    a = Mittsu::Vector4.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(1, a.w)

    a.set_component(0, 1)
    a.set_component(1, 2)
    a.set_component(2, 3)
    a.set_component(3, 4)
    assert_equal(1, a.get_component(0))
    assert_equal(2, a.get_component(1))
    assert_equal(3, a.get_component(2))
    assert_equal(4, a.get_component(3))
  end

  def test_add
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new(-x, -y, -z, -w)

    a.add(b)
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(0, a.w)

    c = Mittsu::Vector4.new.add_vectors(b, b)
    assert_equal(-2*x, c.x)
    assert_equal(-2*y, c.y)
    assert_equal(-2*z, c.z)
    assert_equal(-2*w, c.w)
  end

  def test_sub
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new(-x, -y, -z, -w)

    a.sub(b)
    assert_equal(2*x, a.x)
    assert_equal(2*y, a.y)
    assert_equal(2*z, a.z)
    assert_equal(2*w, a.w)

    c = Mittsu::Vector4.new.sub_vectors(a, a)
    assert_equal(0, c.x)
    assert_equal(0, c.y)
    assert_equal(0, c.z)
    assert_equal(0, c.w)
  end

  def test_multiply_divide
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new(-x, -y, -z, -w)

    a.multiply_scalar(-2)
    assert_equal(x*-2, a.x)
    assert_equal(y*-2, a.y)
    assert_equal(z*-2, a.z)
    assert_equal(w*-2, a.w)

    b.multiply_scalar(-2)
    assert_equal(2*x, b.x)
    assert_equal(2*y, b.y)
    assert_equal(2*z, b.z)
    assert_equal(2*w, b.w)

    a.divide_scalar(-2)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
    assert_equal(w, a.w)

    b.divide_scalar(-2)
    assert_equal(-x, b.x)
    assert_equal(-y, b.y)
    assert_equal(-z, b.z)
    assert_equal(-w, b.w)
  end

  def test_min_max_clamp
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new(-x, -y, -z, -w)
    c = Mittsu::Vector4.new

    c.copy(a).min(b)
    assert_equal(-x, c.x)
    assert_equal(-y, c.y)
    assert_equal(-z, c.z)
    assert_equal(-w, c.w)

    c.copy(a).max(b)
    assert_equal(x, c.x)
    assert_equal(y, c.y)
    assert_equal(z, c.z)
    assert_equal(w, c.w)

    c.set(-2*x, 2*y, -2*z, 2*w)
    c.clamp(b, a)
    assert_equal(-x, c.x)
    assert_equal(y, c.y)
    assert_equal(-z, c.z)
    assert_equal(w, c.w)
  end

  def test_negate
    a = Mittsu::Vector4.new(x, y, z, w)

    a.negate
    assert_equal(-x, a.x)
    assert_equal(-y, a.y)
    assert_equal(-z, a.z)
    assert_equal(-w, a.w)
  end

  def test_dot
    a = Mittsu::Vector4.new(x, y, z, w)
    b = Mittsu::Vector4.new(-x, -y, -z, -w)
    c = Mittsu::Vector4.new(0, 0, 0, 0)

    result = a.dot(b)
    assert_equal((-x*x-y*y-z*z-w*w), result)

    result = a.dot(c)
    assert_equal(0, result)
  end

  def test_length_length_sq
    a = Mittsu::Vector4.new(x, 0, 0, 0)
    b = Mittsu::Vector4.new(0, -y, 0, 0)
    c = Mittsu::Vector4.new(0, 0, z, 0)
    d = Mittsu::Vector4.new(0, 0, 0, w)
    e = Mittsu::Vector4.new(0, 0, 0, 0)

    assert_equal(x, a.length)
    assert_equal(x*x, a.length_sq)
    assert_equal(y, b.length)
    assert_equal(y*y, b.length_sq)
    assert_equal(z, c.length)
    assert_equal(z*z, c.length_sq)
    assert_equal(w, d.length)
    assert_equal(w*w, d.length_sq)
    assert_equal(0, e.length)
    assert_equal(0, e.length_sq)

    a.set(x, y, z, w)
    assert_equal(Math.sqrt(x*x + y*y + z*z + w*w), a.length)
    assert_equal((x*x + y*y + z*z + w*w), a.length_sq)
  end

  def test_normalize
    a = Mittsu::Vector4.new(x, 0, 0, 0)
    b = Mittsu::Vector4.new(0, -y, 0, 0)
    c = Mittsu::Vector4.new(0, 0, z, 0)
    d = Mittsu::Vector4.new(0, 0, 0, -w)

    a.normalize
    assert_equal(1, a.length)
    assert_equal(1, a.x)

    b.normalize
    assert_equal(1, b.length)
    assert_equal(-1, b.y)

    c.normalize
    assert_equal(1, c.length)
    assert_equal(1, c.z)

    d.normalize
    assert_equal(1, d.length)
    assert_equal(-1, d.w)
  end

  def test_distance_to_distance_to_squared
  #  a = Mittsu::Vector4.new(x, 0, 0, 0)
  #  b = Mittsu::Vector4.new(0, -y, 0, 0)
  #  c = Mittsu::Vector4.new(0, 0, z, 0)
  #  d = Mittsu::Vector4.new(0, 0, 0, -w)
  #  e = Mittsu::Vector4.new
  #
  #  assert_equal(x, a.distance_to(e))
  #  assert_equal(x*x, a.distance_to_squared(e))
  #
  #  assert_equal(y, b.distance_to(e))
  #  assert_equal(y*y, b.distance_to_squared(e))
  #
  #  assert_equal(z, c.distance_to(e))
  #  assert_equal(z*z, c.distance_to_squared(e))
  #
  #  assert_equal(w, d.distance_to(e))
  #  assert_equal(w*w, d.distance_to_squared(e))
  end


  def test_set_length
    a = Mittsu::Vector4.new(x, 0, 0, 0)

    assert_equal(x, a.length)
    a.set_length(y)
    assert_equal(y, a.length)

    a = Mittsu::Vector4.new(0, 0, 0, 0)
    assert_equal(0, a.length)
    a.set_length(y)
    assert_equal(0, a.length)
  end

  def test_lerp_clone
    a = Mittsu::Vector4.new(x, 0, z, 0)
    b = Mittsu::Vector4.new(0, -y, 0, -w)

    assert_equal(a.lerp(a, 0.5), a.lerp(a, 0))
    assert_equal(a.lerp(a, 1), a.lerp(a, 0))

    assert_equal(a, a.clone.lerp(b, 0))

    assert_equal(x*0.5, a.clone.lerp(b, 0.5).x)
    assert_equal(-y*0.5, a.clone.lerp(b, 0.5).y)
    assert_equal(z*0.5, a.clone.lerp(b, 0.5).z)
    assert_equal(-w*0.5, a.clone.lerp(b, 0.5).w)

    assert_equal(b, a.clone.lerp(b, 1))
  end

  def test_equals
    a = Mittsu::Vector4.new(x, 0, z, 0)
    b = Mittsu::Vector4.new(0, -y, 0, -w)

    refute_equal(b.x, a.x)
    refute_equal(b.y, a.y)
    refute_equal(b.z, a.z)
    refute_equal(b.w, a.w)

    refute_equal(b, a)
    refute_equal(a, b)

    a.copy(b)
    assert_equal(b.x, a.x)
    assert_equal(b.y, a.y)
    assert_equal(b.z, a.z)
    assert_equal(b.w, a.w)

    assert_equal(b, a)
    assert_equal(a, b)
  end
end
