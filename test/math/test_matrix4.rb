require 'minitest_helper'

class TestMatrix4 < Minitest::Test

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

  def test_constructor
    a = Mittsu::Matrix4.new
    assert_equal(1, a.determinant)

    b = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    assert_equal(0, b.elements[0], "Element 0")
    assert_equal(4, b.elements[1], "Element 1")
    assert_equal(8, b.elements[2], "Element 2")
    assert_equal(12, b.elements[3], "Element 3")
    assert_equal(1, b.elements[4], "Element 4")
    assert_equal(5, b.elements[5], "Element 5")
    assert_equal(9, b.elements[6], "Element 6")
    assert_equal(13, b.elements[7], "Element 7")
    assert_equal(2, b.elements[8], "Element 8")
    assert_equal(6, b.elements[9], "Element 9")
    assert_equal(10, b.elements[10], "Element 10")
    assert_equal(14, b.elements[11], "Element 11")
    assert_equal(3, b.elements[12], "Element 12")
    assert_equal(7, b.elements[13], "Element 13")
    assert_equal(11, b.elements[14], "Element 14")
    assert_equal(15, b.elements[15], "Element 15")

    refute_matrix_equals4(a, b)
  end

  def test_copy
    a = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    b = Mittsu::Matrix4.new.copy(a)

    assert_matrix_equals4(a, b)

    # ensure that it is a true copy
    a.elements[0] = 2
    refute_matrix_equals4(a, b)
  end

  def test_set
    b = Mittsu::Matrix4.new
    assert_equal(1, b.determinant)

    b.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    assert_equal(0, b.elements[0], "Element 0")
    assert_equal(4, b.elements[1], "Element 1")
    assert_equal(8, b.elements[2], "Element 2")
    assert_equal(12, b.elements[3], "Element 3")
    assert_equal(1, b.elements[4], "Element 4")
    assert_equal(5, b.elements[5], "Element 5")
    assert_equal(9, b.elements[6], "Element 6")
    assert_equal(13, b.elements[7], "Element 7")
    assert_equal(2, b.elements[8], "Element 8")
    assert_equal(6, b.elements[9], "Element 9")
    assert_equal(10, b.elements[10], "Element 10")
    assert_equal(14, b.elements[11], "Element 11")
    assert_equal(3, b.elements[12], "Element 12")
    assert_equal(7, b.elements[13], "Element 13")
    assert_equal(11, b.elements[14], "Element 14")
    assert_equal(15, b.elements[15], "Element 15")
  end

  def test_identity
    b = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    assert_equal(0, b.elements[0], "Element 0")
    assert_equal(4, b.elements[1], "Element 1")
    assert_equal(8, b.elements[2], "Element 2")
    assert_equal(12, b.elements[3], "Element 3")
    assert_equal(1, b.elements[4], "Element 4")
    assert_equal(5, b.elements[5], "Element 5")
    assert_equal(9, b.elements[6], "Element 6")
    assert_equal(13, b.elements[7], "Element 7")
    assert_equal(2, b.elements[8], "Element 8")
    assert_equal(6, b.elements[9], "Element 9")
    assert_equal(10, b.elements[10], "Element 10")
    assert_equal(14, b.elements[11], "Element 11")
    assert_equal(3, b.elements[12], "Element 12")
    assert_equal(7, b.elements[13], "Element 13")
    assert_equal(11, b.elements[14], "Element 14")
    assert_equal(15, b.elements[15], "Element 15")

    a = Mittsu::Matrix4.new
    refute_matrix_equals4(a, b)

    b.identity
    assert_matrix_equals4(a, b)
  end

  def test_multiply_scalar
    b = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    assert_equal(0, b.elements[0], "Element 0 Before")
    assert_equal(4, b.elements[1], "Element 1 Before")
    assert_equal(8, b.elements[2], "Element 2 Before")
    assert_equal(12, b.elements[3], "Element 3 Before")
    assert_equal(1, b.elements[4], "Element 4 Before")
    assert_equal(5, b.elements[5], "Element 5 Before")
    assert_equal(9, b.elements[6], "Element 6 Before")
    assert_equal(13, b.elements[7], "Element 7 Before")
    assert_equal(2, b.elements[8], "Element 8 Before")
    assert_equal(6, b.elements[9], "Element 9 Before")
    assert_equal(10, b.elements[10], "Element 10 Before")
    assert_equal(14, b.elements[11], "Element 11 Before")
    assert_equal(3, b.elements[12], "Element 12 Before")
    assert_equal(7, b.elements[13], "Element 13 Before")
    assert_equal(11, b.elements[14], "Element 14 Before")
    assert_equal(15, b.elements[15], "Element 15 Before")

    b.multiply_scalar(2)
    assert_equal(0*2, b.elements[0], "Element 0 After")
    assert_equal(4*2, b.elements[1], "Element 1 After")
    assert_equal(8*2, b.elements[2], "Element 2 After")
    assert_equal(12*2, b.elements[3], "Element 3 After")
    assert_equal(1*2, b.elements[4], "Element 4 After")
    assert_equal(5*2, b.elements[5], "Element 5 After")
    assert_equal(9*2, b.elements[6], "Element 6 After")
    assert_equal(13*2, b.elements[7], "Element 7 After")
    assert_equal(2*2, b.elements[8], "Element 8 After")
    assert_equal(6*2, b.elements[9], "Element 9 After")
    assert_equal(10*2, b.elements[10], "Element 10 After")
    assert_equal(14*2, b.elements[11], "Element 11 After")
    assert_equal(3*2, b.elements[12], "Element 12 After")
    assert_equal(7*2, b.elements[13], "Element 13 After")
    assert_equal(11*2, b.elements[14], "Element 14 After")
    assert_equal(15*2, b.elements[15], "Element 15 After")
  end

  def test_determinant
    a = Mittsu::Matrix4.new
    assert_equal(1, a.determinant)

    a.elements[0] = 2
    assert_equal(2, a.determinant)

    a.elements[0] = 0
    assert_equal(0, a.determinant)

    # calculated via http:#www.euclideanspace.com/maths/algebra/matrix/functions/determinant/fourD/index.htm
    a.set(2, 3, 4, 5, -1, -21, -3, -4, 6, 7, 8, 10, -8, -9, -10, -12)
    assert_equal(76, a.determinant)
  end

  def test_get_inverse
    identity = Mittsu::Matrix4.new

    a = Mittsu::Matrix4.new
    b = Mittsu::Matrix4.new.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    c = Mittsu::Matrix4.new.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    refute_matrix_equals4(a, b)
    b.inverse(a, false)
    assert_matrix_equals4(b, Mittsu::Matrix4.new)

    assert_raises { b.inverse(c, true) }

    test_matrices = [
      Mittsu::Matrix4.new.make_rotation_x(0.3),
      Mittsu::Matrix4.new.make_rotation_x(-0.3),
      Mittsu::Matrix4.new.make_rotation_y(0.3),
      Mittsu::Matrix4.new.make_rotation_y(-0.3),
      Mittsu::Matrix4.new.make_rotation_z(0.3),
      Mittsu::Matrix4.new.make_rotation_z(-0.3),
      Mittsu::Matrix4.new.make_scale(1, 2, 3),
      Mittsu::Matrix4.new.make_scale(1.0/8.0, 1.0/2.0, 1.0/3.0),
      Mittsu::Matrix4.new.make_frustum(-1, 1, -1, 1, 1, 1000),
      Mittsu::Matrix4.new.make_frustum(-16, 16, -9, 9, 0.1, 10000),
      Mittsu::Matrix4.new.make_translation(1, 2, 3)
    ]

    test_matrices.each do |m|
      m_inverse = Mittsu::Matrix4.new.inverse(m)
      m_self_inverse = m.clone
      m_self_inverse.inverse(m_self_inverse)

      # self-inverse should the same as inverse
      assert_matrix_equals4(m_self_inverse, m_inverse)

      # the determinant of the inverse should be the reciprocal
      assert_in_delta(1.0, m.determinant * m_inverse.determinant, 0.0001)

      m_product = Mittsu::Matrix4.new.multiply_matrices(m, m_inverse)

      # the determinant of the identity matrix is 1
      assert_in_delta(1.0, m_product.determinant, 0.0001)
      assert_matrix_equals4(m_product, identity)
    end
  end

  def test_make_basis_extract_basis
    identity_basis = [ Mittsu::Vector3.new(1, 0, 0), Mittsu::Vector3.new(0, 1, 0), Mittsu::Vector3.new(0, 0, 1) ]
    a = Mittsu::Matrix4.new.make_basis(identity_basis[0], identity_basis[1], identity_basis[2])
    identity = Mittsu::Matrix4.new
    assert_matrix_equals4(a, identity)

    test_bases = [ [ Mittsu::Vector3.new(0, 1, 0), Mittsu::Vector3.new(-1, 0, 0), Mittsu::Vector3.new(0, 0, 1) ] ]
    test_bases.each do |test_basis|
      b = Mittsu::Matrix4.new.make_basis(test_basis[0], test_basis[1], test_basis[2])
      out_basis = [ Mittsu::Vector3.new, Mittsu::Vector3.new, Mittsu::Vector3.new ]
      b.extract_basis(out_basis[0], out_basis[1], out_basis[2])
      # check what goes in, is what comes out.
      out_basis.each_index do |j|
        assert_equal(test_basis[j], out_basis[j])
      end

      # get the basis out the hard war
      identity_basis.each_index do |j|
        out_basis[j].copy(identity_basis[j])
        out_basis[j].apply_matrix4(b)
      end
      # did the multiply method of basis extraction work?
      out_basis.each_index do |j|
        assert_equal(test_basis[j], out_basis[j])
      end
    end
  end

  def test_transpose
    a = Mittsu::Matrix4.new
    b = a.clone.transpose
    assert_matrix_equals4(a, b)

    b = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    c = b.clone.transpose
    refute_matrix_equals4(b, c)
    c.transpose
    assert_matrix_equals4(b, c)
  end

  def test_clone
    a = Mittsu::Matrix4.new.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
    b = a.clone

    assert_matrix_equals4(a, b)

    # ensure that it is a true copy
    a.elements[0] = 2.0
    refute_matrix_equals4(a, b)
  end


  def test_compose_decompose
    skip
    t_vlaues = [
      Mittsu::Vector3.new,
      Mittsu::Vector3.new(3, 0, 0),
      Mittsu::Vector3.new(0, 4, 0),
      Mittsu::Vector3.new(0, 0, 5),
      Mittsu::Vector3.new(-6, 0, 0),
      Mittsu::Vector3.new(0, -7, 0),
      Mittsu::Vector3.new(0, 0, -8),
      Mittsu::Vector3.new(-2, 5, -9),
      Mittsu::Vector3.new(-2, -5, -9)
    ]

    s_values = [
      Mittsu::Vector3.new(1, 1, 1),
      Mittsu::Vector3.new(2, 2, 2),
      Mittsu::Vector3.new(1, -1, 1),
      Mittsu::Vector3.new(-1, 1, 1),
      Mittsu::Vector3.new(1, 1, -1),
      Mittsu::Vector3.new(2, -2, 1),
      Mittsu::Vector3.new(-1, 2, -2),
      Mittsu::Vector3.new(-1, -1, -1),
      Mittsu::Vector3.new(-2, -2, -2)
    ]

    r_values = [
      Mittsu::Quaternion.new,
      Mittsu::Quaternion.new.set_from_euler( Mittsu::Euler.new(1, 1, 0) ),
      Mittsu::Quaternion.new.set_from_euler( Mittsu::Euler.new(1, -1, 1) ),
      Mittsu::Quaternion.new(0, 0.9238795292366128, 0, 0.38268342717215614)
    ]

    t_vlaues.each do |t|
      s_values.each do |s|
        r_values.each do |r|
          m = Mittsu::Matrix4.new.compose(t, r, s)
          t2 = Mittsu::Vector3.new
          r2 = Mittsu::Quaternion.new
          s2 = Mittsu::Vector3.new

          m.decompose(t2, r2, s2)

          m2 = Mittsu::Matrix4.new.compose(t2, r2, s2)

          assert_matrix_equals4(m, m2)
        end
      end
    end
  end
end
