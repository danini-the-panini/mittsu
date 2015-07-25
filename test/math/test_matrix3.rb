require 'minitest_helper'

class TestMatrix3 < Minitest::Test

  def matrix_equals3(a, b, tolerance = 0.0001)
    return false if a.elements.length != b.elements.length
    a.elements.each_with_index do |e, i|
      delta = e - b.elements[i]
      return false if delta > tolerance
    end
    true
  end

  def assert_matrix_equals3(a, b, tolerance = 0.0001)
    assert(matrix_equals3(a, b, tolerance), "#{a} does not equal #{b}")
  end

  def refute_matrix_equals3(a, b, tolerance = 0.0001)
    refute(matrix_equals3(a, b, tolerance), "#{a} equals #{b}")
  end

  def to_matrix4(m3)
    result = Mittsu::Matrix4.new
    re = result.elements
    me = m3.elements
    re[0] = me[0]
    re[1] = me[1]
    re[2] = me[2]
    re[4] = me[3]
    re[5] = me[4]
    re[6] = me[5]
    re[8] = me[6]
    re[9] = me[7]
    re[10] = me[8]
    result
  end

  def test_constructor
    a = Mittsu::Matrix3.new
    assert_equal(1, a.determinant)

    b = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    assert_equal(0, b.elements[0], 'Element 0')
    assert_equal(3, b.elements[1], 'Element 1')
    assert_equal(6, b.elements[2], 'Element 2')
    assert_equal(1, b.elements[3], 'Element 3')
    assert_equal(4, b.elements[4], 'Element 4')
    assert_equal(7, b.elements[5], 'Element 5')
    assert_equal(2, b.elements[6], 'Element 6')
    assert_equal(5, b.elements[7], 'Element 7')
    assert_equal(8, b.elements[8], 'Element 8')

    refute_matrix_equals3(a, b)
  end

  def test_copy
    a = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    b = Mittsu::Matrix3.new.copy(a)

    assert_matrix_equals3(a, b)

    # ensure that it is a true copy
    a.elements[0] = 2
    refute_matrix_equals3(a, b)
  end

  def test_set
    b = Mittsu::Matrix3.new
    assert_equal(1, b.determinant)

    b.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    assert_equal(0, b.elements[0], "Element 0")
    assert_equal(3, b.elements[1], "Element 1")
    assert_equal(6, b.elements[2], "Element 2")
    assert_equal(1, b.elements[3], "Element 3")
    assert_equal(4, b.elements[4], "Element 4")
    assert_equal(7, b.elements[5], "Element 5")
    assert_equal(2, b.elements[6], "Element 6")
    assert_equal(5, b.elements[7], "Element 7")
    assert_equal(8, b.elements[8], "Element 8")
  end

  def test_identity
    b = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    assert_equal(0, b.elements[0], "Element 0")
    assert_equal(3, b.elements[1], "Element 1")
    assert_equal(6, b.elements[2], "Element 2")
    assert_equal(1, b.elements[3], "Element 3")
    assert_equal(4, b.elements[4], "Element 4")
    assert_equal(7, b.elements[5], "Element 5")
    assert_equal(2, b.elements[6], "Element 6")
    assert_equal(5, b.elements[7], "Element 7")
    assert_equal(8, b.elements[8], "Element 8")

    a = Mittsu::Matrix3.new
    refute_matrix_equals3(a, b)

    b.identity
    assert_matrix_equals3(a, b)
  end

  def test_multiply_scalar
    b = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    assert_equal(0, b.elements[0], "Element 0 Before")
    assert_equal(3, b.elements[1], "Element 1 Before")
    assert_equal(6, b.elements[2], "Element 2 Before")
    assert_equal(1, b.elements[3], "Element 3 Before")
    assert_equal(4, b.elements[4], "Element 4 Before")
    assert_equal(7, b.elements[5], "Element 5 Before")
    assert_equal(2, b.elements[6], "Element 6 Before")
    assert_equal(5, b.elements[7], "Element 7 Before")
    assert_equal(8, b.elements[8], "Element 8 Before")

    b.multiply_scalar(2)
    assert_equal(0*2, b.elements[0], "Element 0 After")
    assert_equal(3*2, b.elements[1], "Element 1 After")
    assert_equal(6*2, b.elements[2], "Element 2 After")
    assert_equal(1*2, b.elements[3], "Element 3 After")
    assert_equal(4*2, b.elements[4], "Element 4 After")
    assert_equal(7*2, b.elements[5], "Element 5 After")
    assert_equal(2*2, b.elements[6], "Element 6 After")
    assert_equal(5*2, b.elements[7], "Element 7 After")
    assert_equal(8*2, b.elements[8], "Element 8 After")
  end


  def test_determinant
    a = Mittsu::Matrix3.new
    assert_equal(1, a.determinant)

    a.elements[0] = 2.0
    assert_equal(2, a.determinant)

    a.elements[0] = 0.0
    assert_equal(0.0, a.determinant)

    # calculated via http:#www.euclideanspace.com/maths/algebra/matrix/functions/determinant/threeD/index.htm
    a.set(2, 3, 4, 5, 13, 7, 8, 9, 11)
    assert_equal(-73, a.determinant)
  end


  def test_get_inverse
    skip
    identity = Mittsu::Matrix4.new
    a = Mittsu::Matrix4.new
    b = Mittsu::Matrix3.new.set(0, 0, 0, 0, 0, 0, 0, 0, 0)
    c = Mittsu::Matrix4.new.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    refute_matrix_equals3(a, b)
    b.inverse(a, false)
    assert_matrix_equals3(b, Mittsu::Matrix3.new)

    assert_raises { b.inverse(c, true) }

    test_matrices = [
      Mittsu::Matrix4.new.make_rotation_x(0.3),
      Mittsu::Matrix4.new.make_rotation_x(-0.3),
      Mittsu::Matrix4.new.make_rotation_y(0.3),
      Mittsu::Matrix4.new.make_rotation_y(-0.3),
      Mittsu::Matrix4.new.make_rotation_z(0.3),
      Mittsu::Matrix4.new.make_rotation_z(-0.3),
      Mittsu::Matrix4.new.make_scale(1, 2, 3),
      Mittsu::Matrix4.new.make_scale(1/8, 1/2, 1/3)
    ]

    test_matrices.each do |m|
      m_inverse3 = Mittsu::Matrix3.new.inverse(m)

      m_inverse = to_matrix4(m_inverse3)

      # the determinant of the inverse should be the reciprocal
      assert_in_delta(1.0, m.determinant * m_inverse3.determinant, 0.0001)
      assert_in_delta(1.0, m.determinant * m_inverse.determinant, 0.0001)

      m_product = Mittsu::Matrix4.new.multiply_matrices(m, m_inverse)
      assert_in_delta(1.0, m_product.determinant, 0.0001)
      assert_matrix_equals3(m_product, identity)
    end
  end

  def test_transpose
    a = Mittsu::Matrix3.new
    b = a.clone.transpose
    assert_matrix_equals3(a, b)

    b = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    c = b.clone.transpose
    refute_matrix_equals3(b, c)
    c.transpose
    assert_matrix_equals3(b, c)
  end

  def test_clone
    a = Mittsu::Matrix3.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8)
    b = a.clone

    assert_matrix_equals3(a, b)

    # ensure that it is a true copy
    a.elements[0] = 2.0
    refute_matrix_equals3(a, b)
  end
end
