require 'minitest_helper'

class TestMath < Minitest::Test
  def test_sign_nan
    sign = Math.sign(Float::NAN)

    assert_predicate sign, :nan?
  end

  def test_sign_object
    sign = Math.sign(Object.new)

    assert_predicate sign, :nan?
  end

  def test_sign_nil
    sign = Math.sign(nil)

    assert_predicate sign, :nan?
  end

  def test_sign_negative_zero
    x = -0.0
    sign = Math.sign(x)

    assert_same(x, sign)
  end

  def test_sign_positive_zero
    sign = Math.sign(0.0)

    assert_same(0.0, sign)
  end

  def test_sign_negative_infinity
    sign = Math.sign(-Float::INFINITY)

    assert_same(-1.0, sign)
  end

  def test_sign_negative_number
    sign = Math.sign(-3)

    assert_same(-1.0, sign)
  end

  def test_sign_negative_small_number
    sign = Math.sign(-1e-10)

    assert_same(-1.0, sign)
  end

  def test_sign_positive_infinity
    sign = Math.sign(Float::INFINITY)

    assert_same(1.0, sign)
  end

  def test_sign_positive_number
    sign = Math.sign(3)

    assert_same(1.0, sign)
  end
end
