require 'minitest_helper'

class TestColor < Minitest::Test

  def test_constructor
    c = Mittsu::Color.new
    assert(c.r > 0, "Red: #{c.r}")
    assert(c.g > 0, "Green: #{c.g}")
    assert(c.b > 0, "Blue: #{c.b}")
  end

  def test_rgb_constructor
    c = Mittsu::Color.new(1, 1, 1)
    assert_equal(1, c.r)
    assert_equal(1, c.g)
    assert_equal(1, c.b)
  end

  def test_copy_hex
    c = Mittsu::Color.new
    c2 = Mittsu::Color.new(0xF5FFFA)
    c.copy(c2)
    assert_equal(c2.hex, c.hex, "Hex c: #{c.hex} Hex c2: #{c2.hex}")
  end

  def test_copy_color_string
    c = Mittsu::Color.new
    c2 = Mittsu::Color.new('ivory')
    c.copy(c2)
    assert_equal(c2.hex, c.hex, "Hex c: #{c.hex} Hex c2: #{c2.hex}")
  end

  def test_set_rgb
    c = Mittsu::Color.new
    c.set_rgb(1, 0.2, 0.1)
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0.2, c.g, "Green: #{c.g}")
    assert_equal(0.1, c.b, "Blue: #{c.b}")
  end

  def test_copy_gamma_to_linear
    c = Mittsu::Color.new
    c2 = Mittsu::Color.new
    c2.set_rgb(0.3, 0.5, 0.9)
    c.copy_gamma_to_linear(c2)
    assert_equal(0.09,  c.r, "Red c: #{c.r} Red c2: #{c2.r}")
    assert_equal(0.25,  c.g, "Green c: #{c.g} Green c2: #{c2.g}")
    assert_equal(0.81,  c.b, "Blue c: #{c.b} Blue c2: #{c2.b}")
  end

  def test_copy_linear_to_gamma
    c = Mittsu::Color.new
    c2 = Mittsu::Color.new
    c2.set_rgb(0.09, 0.25, 0.81)
    c.copy_linear_to_gamma(c2)
    assert_equal(0.3,  c.r, "Red c: #{c.r} Red c2: #{c2.r}")
    assert_equal(0.5,  c.g, "Green c: #{c.g} Green c2: #{c2.g}")
    assert_equal(0.9,  c.b, "Blue c: #{c.b} Blue c2: #{c2.b}")
  end


  def test_convert_gamma_to_linear
    c = Mittsu::Color.new
    c.set_rgb(0.3, 0.5, 0.9)
    c.convert_gamma_to_linear
    assert_equal(0.09, c.r, "Red: #{c.r}")
    assert_equal(0.25, c.g, "Green: #{c.g}")
    assert_equal(0.81, c.b, "Blue: #{c.b}")
  end


  def test_convert_linear_to_gamma
    c = Mittsu::Color.new
    c.set_rgb(4, 9, 16)
    c.convert_linear_to_gamma
    assert_equal(2, c.r, "Red: #{c.r}")
    assert_equal(3, c.g, "Green: #{c.g}")
    assert_equal(4, c.b, "Blue: #{c.b}")
  end

  def test_set_with_num
    c = Mittsu::Color.new
    c.set(0xFF0000)
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0, c.g, "Green: #{c.g}")
    assert_equal(0, c.b, "Blue: #{c.b}")
  end


  def test_set_with_string
    c = Mittsu::Color.new
    c.set('silver')
    assert_equal(0xC0C0C0, c.hex, "Hex c: #{c.hex}")
  end

  def test_clone
    c = Mittsu::Color.new('teal')
    c2 = c.clone
    assert_equal(0x008080, c2.hex, "Hex c2: #{c2.hex}")
  end

  def test_lerp
    c = Mittsu::Color.new
    c2 = Mittsu::Color.new
    c.set_rgb(0, 0, 0)
    c.lerp(c2, 0.2)
    assert_equal(0.2, c.r, "Red: #{c.r}")
    assert_equal(0.2, c.g, "Green: #{c.g}")
    assert_equal(0.2, c.b, "Blue: #{c.b}")
  end

  def test_set_style_rgb_red
    c = Mittsu::Color.new
    c.set_style('rgb(255,0,0)')
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0, c.g, "Green: #{c.g}")
    assert_equal(0, c.b, "Blue: #{c.b}")
  end

  def test_set_style_rgb_red_with_spaces
    c = Mittsu::Color.new
    c.set_style('rgb(255, 0, 0)')
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0, c.g, "Green: #{c.g}")
    assert_equal(0, c.b, "Blue: #{c.b}")
  end

  def test_set_style_rgb_percent
    c = Mittsu::Color.new
    c.set_style('rgb(100%,50%,10%)')
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0.5, c.g, "Green: #{c.g}")
    assert_equal(0.1, c.b, "Blue: #{c.b}")
  end

  def test_set_style_rgb_percent_with_spaces
    c = Mittsu::Color.new
    c.set_style('rgb(100%,50%,10%)')
    assert_equal(1, c.r, "Red: #{c.r}")
    assert_equal(0.5, c.g, "Green: #{c.g}")
    assert_equal(0.1, c.b, "Blue: #{c.b}")
  end

  def test_set_style_hex_sky_blue
    c = Mittsu::Color.new
    c.set_style('#87CEEB')
    assert_equal(0x87CEEB, c.hex, "Hex c: #{c.hex}")
  end

  def test_set_style_hex_2O_live
    c = Mittsu::Color.new
    c.set_style('#F00')
    assert_equal(0xFF0000, c.hex, "Hex c: #{c.hex}")
  end

  def test_set_style_color_name
    c = Mittsu::Color.new
    c.set_style('powderblue')
    assert_equal(0xB0E0E6, c.hex, "Hex c: #{c.hex}")
  end

  def test_get_hex
    c = Mittsu::Color.new('red')
    res = c.hex
    assert_equal(0xFF0000, res, "Hex: #{res}")
  end

  def test_set_hex
    c = Mittsu::Color.new
    c.set_hex(0xFA8072)
    assert_equal(0xFA8072,  c.hex, "Hex: #{c.hex}")
  end

  def test_get_hex_string
    c = Mittsu::Color.new('tomato')
    res = c.hex_string
    assert_equal('ff6347', res, "Hex: #{res}")
  end

  def test_get_style
    c = Mittsu::Color.new('plum')
    res = c.style
    assert( res == 'rgb(221,160,221)', "style: #{res }")
  end

  def test_get_hsl
    c = Mittsu::Color.new(0x80ffff)
    hsl = c.hsl

    assert_equal(0.5, hsl[:h], "hue: #{hsl[:h]}")
    assert_equal(1.0, hsl[:s], "saturation: #{hsl[:s]}")
    assert_equal(0.75, ((hsl[:l].to_f*100.0).round/100.0), "lightness: #{hsl[:l] }")
  end

  def test_set_hsl
    c = Mittsu::Color.new
    c.set_hsl(0.75, 1.0, 0.25)
    hsl = c.hsl

    assert_equal(0.75, hsl[:h], "hue: #{hsl[:h]}")
    assert_equal(1.00, hsl[:s], "saturation: #{hsl[:s]}")
    assert_equal(0.25, hsl[:l], "lightness: #{hsl[:l]}")
  end
end
