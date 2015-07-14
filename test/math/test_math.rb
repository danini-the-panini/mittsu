require 'minitest_helper'

class TestMath < Minitest::Test
  DELTA = 0.000000000001
  RANDOM_SAMPLES = 10000

  def test_sign_nan
    sign = Mittsu::Math.sign(Float::NAN)

    assert_predicate sign, :nan?
  end

  def test_sign_object
    sign = Mittsu::Math.sign(Object.new)

    assert_predicate sign, :nan?
  end

  def test_sign_nil
    sign = Mittsu::Math.sign(nil)

    assert_predicate sign, :nan?
  end

  def test_sign_negative_zero
    x = -0.0
    sign = Mittsu::Math.sign(x)

    assert_same(x, sign)
  end

  def test_sign_positive_zero
    sign = Mittsu::Math.sign(0.0)

    assert_same(0.0, sign)
  end

  def test_sign_negative_infinity
    sign = Mittsu::Math.sign(-Float::INFINITY)

    assert_same(-1.0, sign)
  end

  def test_sign_negative_number
    sign = Mittsu::Math.sign(-3)

    assert_same(-1.0, sign)
  end

  def test_sign_negative_small_number
    sign = Mittsu::Math.sign(-1e-10)

    assert_same(-1.0, sign)
  end

  def test_sign_positive_infinity
    sign = Mittsu::Math.sign(Float::INFINITY)

    assert_same(1.0, sign)
  end

  def test_sign_positive_number
    sign = Mittsu::Math.sign(3)

    assert_same(1.0, sign)
  end

  def test_clamp_less_than_range
    assert_equal 3, Mittsu::Math.clamp(2, 3, 7)
  end

  def test_clamp_in_range
    assert_equal 5, Mittsu::Math.clamp(5, 3, 7)
  end

  def test_clamp_greater_than_range
    assert_equal 7, Mittsu::Math.clamp(8, 3, 7)
  end

  def test_clamp_bottom_less_than_limit
    assert_equal 3, Mittsu::Math.clamp_bottom(2, 3)
  end

  def test_clamp_bottom_greater_than_limit
    assert_equal 4, Mittsu::Math.clamp_bottom(4, 3)
  end

  def test_map_linear
    inputs = [ -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1 ]
    outputs = [ -1.2, -1, -0.8, -0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8, 1, 1.2 ]
    inputs.zip(outputs).each do |(input, expected)|
      assert_in_delta expected, Mittsu::Math.map_linear(input, 0, 1, -1, 1), DELTA
    end
  end

  def test_smooth_step
    inputs = [ -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1 ]
    outputs = [
      [ 0, 0, 0.028, 0.104, 0.216, 0.352, 0.5, 0.648, 0.784, 0.896, 0.972, 1, 1 ],
      [ 0.42525, 0.5, 0.57475, 0.648, 0.71825, 0.784, 0.84375, 0.896, 0.93925, 0.972, 0.99275, 1, 1 ]
    ]
    inputs.zip(outputs.reduce(&:zip)).each do |(input, expected)|
      assert_in_delta expected[0], Mittsu::Math.smooth_step(input, 0.0, 1.0), DELTA
      assert_in_delta expected[1], Mittsu::Math.smooth_step(input, -1.0, 1.0), DELTA
    end
  end

  def test_smoother_step
    inputs = [ -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1 ]
    outputs = [
      [ 0, 0, 0.00856, 0.05792, 0.16308, 0.31744, 0.5, 0.68256, 0.83692, 0.94208, 0.99144, 1, 1 ],
      [ 0.406873125, 0.5, 0.593126875, 0.68256, 0.764830625, 0.83692, 0.896484375, 0.94208, 0.973388125, 0.99144,
        0.998841875, 1, 1 ]
    ]
    inputs.zip(outputs.reduce(&:zip)).each do |(input, expected)|
      assert_in_delta expected[0], Mittsu::Math.smoother_step(input, 0.0, 1.0), DELTA
      assert_in_delta expected[1], Mittsu::Math.smoother_step(input, -1.0, 1.0), DELTA
    end
  end

  def test_random16
    RANDOM_SAMPLES.times do
      assert_includes (0..1), Mittsu::Math.random16
    end
  end

  def test_rand_int
    RANDOM_SAMPLES.times do
      [[-10, 10], [0, 100]].each do |(low, high)|
        r = Mittsu::Math.rand_int(low, high)
        assert_kind_of Fixnum, r
        assert_includes (low..high), r
      end
    end
  end

  def test_rand_float
    RANDOM_SAMPLES.times do
      [[-1.0, 1.0], [0.0, 1.0]].each do |(low, high)|
        r = Mittsu::Math.rand_float(low, high)
        assert_kind_of Float, r
        assert_includes (low..high), r
      end
    end
  end

  def test_rand_float_spread
    RANDOM_SAMPLES.times do
      [1.0, 10.0].each do |limit|
        half_limit = limit/2
        r = Mittsu::Math::rand_float_spread(limit)
        assert_kind_of Float, r
        assert_includes (-half_limit..half_limit), r
      end
    end
  end

  def test_deg_to_rad
    inputs = (-360..720).step(30).to_a
    outputs = (-Math::PI*2..Math::PI*4).step(Math::PI/6).to_a
    inputs.zip(outputs).each do |(input, expected)|
      assert_in_delta expected, Mittsu::Math.deg_to_rad(input), DELTA
    end
  end

  def test_rad_to_deg
    inputs = (-Math::PI*2..Math::PI*4).step(Math::PI/6).to_a
    outputs = (-360..720).step(30).to_a
    inputs.zip(outputs).each do |(input, expected)|
      assert_in_delta expected, Mittsu::Math.rad_to_deg(input), DELTA
    end
  end

  def test_power_of_two?
    assert Mittsu::Math.power_of_two?(1), "1 should be a power of two"
    assert Mittsu::Math.power_of_two?(4), "4 should be a power of two"
    assert Mittsu::Math.power_of_two?(2), "2 should be a power of two"
    assert Mittsu::Math.power_of_two?(8192), "8192 should be a power of two"

    refute Mittsu::Math.power_of_two?(0), "0 should not be a power of two"
    refute Mittsu::Math.power_of_two?(3), "3 should not be a power of two"
    refute Mittsu::Math.power_of_two?(12), "12 should not be a power of two"
    refute Mittsu::Math.power_of_two?(8191), "8191 should not be a power of two"
  end

  def test_next_power_of_two
    assert_equal 0, Mittsu::Math.next_power_of_two(0)
    assert_equal 1, Mittsu::Math.next_power_of_two(1)
    assert_equal 2, Mittsu::Math.next_power_of_two(2)
    assert_equal 4, Mittsu::Math.next_power_of_two(3)
    assert_equal 4096, Mittsu::Math.next_power_of_two(4095)
    assert_equal 4096, Mittsu::Math.next_power_of_two(4096)
    assert_equal 8192, Mittsu::Math.next_power_of_two(4097)
  end
end
