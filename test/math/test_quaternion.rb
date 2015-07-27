require 'minitest_helper'

class TestQuaternion < Minitest::Test
  ORDERS = [ 'XYZ', 'YXZ', 'ZXY', 'ZYX', 'YZX', 'XZY' ]
  # EULER_ANGLES = Mittsu::Euler.new(0.1, -0.3, 0.25)

  def q_sub(a, b)
    result = Mittsu::Quaternion.new
    result.copy(a)

    result.x -= b.x
    result.y -= b.y
    result.z -= b.z
    result.w -= b.w

    result
  end

  def test_constructor
    a = Mittsu::Quaternion.new
    assert_equal(0, a.x)
    assert_equal(0, a.y)
    assert_equal(0, a.z)
    assert_equal(1, a.w)

    a = Mittsu::Quaternion.new(x, y, z, w)
    assert_equal(x, a.x)
    assert_equal(y, a.y)
    assert_equal(z, a.z)
    assert_equal(w, a.w)
  end

  def test_copy
    a = Mittsu::Quaternion.new(x, y, z, w)
    b = Mittsu::Quaternion.new.copy(a)
    assert_equal(x, b.x)
    assert_equal(y, b.y)
    assert_equal(z, b.z)
    assert_equal(w, b.w)

    # ensure that it is a true copy
    a.x = 0
    a.y = -1
    a.z = 0
    a.w = -1
    assert_equal(x, b.x)
    assert_equal(y, b.y)
  end

  def test_set
    a = Mittsu::Quaternion.new
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

  def test_set_from_axis_angle

    # TODO: find cases to validate.
    assert(true)

    zero = Mittsu::Quaternion.new

    a = Mittsu::Quaternion.new.set_from_axis_angle( Mittsu::Vector3.new(1, 0, 0), 0 )
    assert_equal(zero, a)
    a = Mittsu::Quaternion.new.set_from_axis_angle( Mittsu::Vector3.new(0, 1, 0), 0 )
    assert_equal(zero, a)
    a = Mittsu::Quaternion.new.set_from_axis_angle( Mittsu::Vector3.new(0, 0, 1), 0 )
    assert_equal(zero, a)

    b1 = Mittsu::Quaternion.new.set_from_axis_angle( Mittsu::Vector3.new(1, 0, 0), Math::PI )
    refute_equal(b1, a)
    b2 = Mittsu::Quaternion.new.set_from_axis_angle( Mittsu::Vector3.new(1, 0, 0), -Math::PI )
    refute_equal(b2, a)

    b1.multiply(b2)
    assert_equal(b1, a)
  end


  def test_set_from_euler_set_from_quaternion
    skip
    angles = [ Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0), Mittsu::Vector3.new(0, 0, 1) ]

    # ensure euler conversion to/from Quaternion matches.
    ORDERS.each do |order|
      angles.each do |angle|
        eulers2 = Mittsu::Euler.new.set_from_quaternion(Mittsu::Quaternion.new.set_from_euler(Mittsu::Euler.new(angle.x, angle.y, angle.z, order)), order)
        newAngle = Mittsu::Vector3.new(eulers2.x, eulers2.y, eulers2.z)
        assert(newAngle.distance_to(angle) < 0.001)
      end
    end

  end

  def test_set_from_euler_set_from_rotation_matrix
    skip
    # ensure euler conversion for Quaternion matches that of Matrix4
    ORDERS.each do |order|
      q = Mittsu::Quaternion.new.set_from_euler(EULER_ANGLES, order)
      m = Mittsu::Matrix4.new.make_rotation_from_euler(EULER_ANGLES, order)
      q2 = Mittsu::Quaternion.new.set_from_rotation_matrix(m)

      assert(q_sub(q, q2).length < 0.001, "Passed!" )
    end
  end

  def test_normalize_length_length_sq
    a = Mittsu::Quaternion.new(x, y, z, w)

    refute_equal(1, a.length)
    refute_equal(1, a.length_sq)
    a.normalize
    assert_equal(1, a.length)
    assert_equal(1, a.length_sq)

    a.set(0, 0, 0, 0)
    assert_equal(0, a.length)
    assert_equal(0, a.length_sq)
    a.normalize
    assert_equal(1, a.length)
    assert_equal(1, a.length_sq)
  end

  def test_inverse_conjugate
    a = Mittsu::Quaternion.new(x, y, z, w)

    # TODO: add better validation here.

    b = a.clone.conjugate

    assert_equal(-b.x, a.x)
    assert_equal(-b.y, a.y)
    assert_equal(-b.z, a.z)
    assert_equal(b.w, a.w)
  end


  def test_multiply_quaternions_multiply
    skip
    angles = [ Mittsu::Euler.new(1, 0, 0), Mittsu::Euler.new(0, 1, 0), Mittsu::Euler.new(0, 0, 1) ]

    q1 = Mittsu::Quaternion.new.set_from_euler(angles[0], "XYZ")
    q2 = Mittsu::Quaternion.new.set_from_euler(angles[1], "XYZ")
    q3 = Mittsu::Quaternion.new.set_from_euler(angles[2], "XYZ")

    q = Mittsu::Quaternion.new.multiply_quaternions(q1, q2).multiply(q3)

    m1 = Mittsu::Matrix4.new.make_rotation_from_euler(angles[0], "XYZ")
    m2 = Mittsu::Matrix4.new.make_rotation_from_euler(angles[1], "XYZ")
    m3 = Mittsu::Matrix4.new.make_rotation_from_euler(angles[2], "XYZ")

    m = Mittsu::Matrix4.new.multiply_matrices(m1, m2).multiply(m3)

    qFromM = Mittsu::Quaternion.new.set_from_rotation_matrix(m)

    ok(q_sub( q, qFromM).length < 0.001, "Passed!" )
  end

  def test_multiply_vector3
    skip
    angles = [ Mittsu::Euler.new(1, 0, 0), Mittsu::Euler.new(0, 1, 0), Mittsu::Euler.new(0, 0, 1) ]

    # ensure euler conversion for Quaternion matches that of Matrix4
    ORDERS.each do |order|
      angles.each do |angle|
        q = Mittsu::Quaternion.new.set_from_euler(angle, order)
        m = Mittsu::Matrix4.new.make_rotation_from_euler(angle, order)

        v0 = Mittsu::Vector2.new(1, 0, 0)
        qv = v0.clone.apply_quaternion(q)
        mv = v0.clone.apply_matrix4(m)

        assert(qv.distance_to(mv) < 0.001)
      end
    end
  end

  def test_equals
    a = Mittsu::Quaternion.new(x, y, z, w)
    b = Mittsu::Quaternion.new(-x, -y, -z, -w)

    refute_equal(b.x, a.x)
    refute_equal(b.y, a.y)

    refute_equal(b, a)
    refute_equal(a, b)

    a.copy(b)
    assert_equal(b.x, a.x)
    assert_equal(b.y, a.y)

    assert_equal(b, a)
    assert_equal(a, b)
  end

  def test_slerp
    a = Mittsu::Quaternion.new(0.675341, 0.408783, 0.328567, 0.518512)
    b = Mittsu::Quaternion.new(0.660279, 0.436474, 0.35119, 0.500187)

    assert_equal(a, a.slerp(b, 0))
    assert_equal(b, a.slerp(b, 1))
  end
end
