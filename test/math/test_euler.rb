require 'minitest_helper'

class TestEuler < Minitest::Test
  EULER_ZERO = Mittsu::Euler.new(0, 0, 0, "XYZ")
  EULER_A_XYZ = Mittsu::Euler.new(1, 0, 0, "XYZ")
  EULER_A_ZYX = Mittsu::Euler.new(0, 1, 0, "ZYX")

  def matrix_equals4(a, b, tolerance = 0.0001)
    return false if a.elements.length != b.elements.length
    a.elements.each_with_index do |e, i|
      delta = e - b.elements[i]
      return false if delta > tolerance
    end
    true
  end

  def assert_matrix_equals4(a, b, tolerance = 0.0001)
    assert(matrix_equals4(a, b, tolerance), "#{a} does not equal #{b}")
  end

  def refute_matrix_equals4(a, b, tolerance = 0.0001)
    refute(matrix_equals4(a, b, tolerance), "#{a} equals #{b}")
  end

  def euler_equals(a, b, tolerance = 0.0001)
    tolerance = tolerance || 0.0001
    diff = (a.x - b.x).abs + (a.y - b.y).abs + (a.z - b.z).abs
    diff < tolerance
  end

  def assert_euler_equals(a, b, tolerance = 0.0001)
    assert(euler_equals(a, b, tolerance), "#{a} does not equal #{b}")
  end

  def refute_euler_equals(a, b, tolerance = 0.0001)
    refute(euler_equals(a, b, tolerance), "#{a} equals #{b}")
  end

  def quat_equals(a, b, tolerance = 0.0001)
    diff = (a.x - b.x).abs + (a.y - b.y).abs + (a.z - b.z).abs + (a.w - b.w).abs
    diff < tolerance
  end

  def assert_quat_equals(a, b, tolerance = 0.0001)
    assert(quat_equals(a, b, tolerance), "#{a} does not equal #{b}")
  end

  def refute_quat_equals(a, b, tolerance = 0.0001)
    refute(quat_equals(a, b, tolerance), "#{a} equals #{b}")
  end

  def test_constructor_equals
    a = Mittsu::Euler.new
    assert_equal(EULER_ZERO, a)
    refute_equal(EULER_A_XYZ, a)
    refute_equal(EULER_A_ZYX, a)
  end

  def test_clone_copy_equals
    a = EULER_A_XYZ.clone
    assert_equal(EULER_A_XYZ, a)
    refute_equal(EULER_ZERO, a)
    refute_equal(EULER_A_ZYX, a)

    a.copy(EULER_A_ZYX)
    assert_equal(EULER_A_ZYX, a)
    refute_equal(EULER_A_XYZ, a)
    refute_equal(EULER_ZERO, a)
  end

  def test_set_set_from_vector3_to_vector3
    a = Mittsu::Euler.new

    a.set(0, 1, 0, "ZYX")
    assert_equal(EULER_A_ZYX, a)
    refute_equal(EULER_A_XYZ, a)
    refute_equal(EULER_ZERO, a)

    vec = Mittsu::Vector3.new(0, 1, 0)

    b = Mittsu::Euler.new.set_from_vector3(vec, "ZYX")
    # console.log(a, b)
    assert_equal(b, a)

    c = b.to_vector3
    # console.log(c, vec)
    assert_equal(vec, c)
  end

  def test_quaternion_set_from_euler_euler_from_quaternion
    [EULER_ZERO, EULER_A_XYZ, EULER_A_ZYX].each do |v|
      q = Mittsu::Quaternion.new.set_from_euler(v)

      v2 = Mittsu::Euler.new.set_from_quaternion(q, v.order)
      q2 = Mittsu::Quaternion.new.set_from_euler(v2)
      assert_euler_equals(q2, q)
    end
  end


  def test_matrix4_set_from_euler_euler_from_rotation_matrix
    [EULER_ZERO, EULER_A_XYZ, EULER_A_ZYX].each do |v|
      m = Mittsu::Matrix4.new.make_rotation_from_euler(v)

      v2 = Mittsu::Euler.new.set_from_rotation_matrix(m, v.order)
      m2 = Mittsu::Matrix4.new.make_rotation_from_euler(v2)
      assert_matrix_equals4(m2, m)
    end
  end

  def test_reorder
    [EULER_ZERO, EULER_A_XYZ, EULER_A_ZYX].each do |v|
      q = Mittsu::Quaternion.new.set_from_euler(v)

      v.reorder('YZX')
      q2 = Mittsu::Quaternion.new.set_from_euler(v)
      assert_quat_equals(q2, q)

      v.reorder('ZXY')
      q3 = Mittsu::Quaternion.new.set_from_euler(v)
      assert_quat_equals(q3, q)
    end
  end

  def test_gimbal_local_quat
    # known problematic quaternions
    q1 = Mittsu::Quaternion.new(0.5207769385244341, -0.4783214164122354, 0.520776938524434, 0.47832141641223547)
    # q2 = Mittsu::Quaternion.new(0.11284905712620674, 0.6980437630368944, -0.11284905712620674, 0.6980437630368944)

    euler_order = "ZYX"

    # create Euler directly from a Quaternion
    e_via_q1 = Mittsu::Euler.new.set_from_quaternion(q1, euler_order) # there is likely a bug here

    # create Euler from Quaternion via an intermediate Matrix4
    m_via_q1 = Mittsu::Matrix4.new.make_rotation_from_quaternion(q1)
    e_via_m_via_q1 = Mittsu::Euler.new.set_from_rotation_matrix(m_via_q1, euler_order)

    # the results here are different
    assert_euler_equals(e_via_m_via_q1, e_via_q1)  # this result is correct

  end
end
