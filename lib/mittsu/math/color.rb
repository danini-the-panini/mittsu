require 'mittsu/math'

module Mittsu
  class Color
    attr_accessor :r, :g, :b

    def initialize(*args)
      case args.length
      when 3 then self.set_rgb(*args)
      when 1 then self.set(args.first)
      when 0 then self.set_rgb(1.0, 1.0, 1.0)
      else raise ArgumentError, "Arguments must be (r, g, b), (color), or none"
      end
    end

    def set(value)
      case value
      when Color
        self.copy(value)
      when Fixnum
        self.set_hex(value)
      when String
        self.set_style(value)
      else
        raise ArgumentError, "Arguments must be Color, Fixnum or String"
      end
      self
    end

    def set_hex(hex)
      hex = hex.floor
      @r = (hex >> 16 & 255) / 255.0
      @g = (hex >> 8 & 255) / 255.0
      @b = (hex & 255) / 255.0
      self
    end

    def set_rgb(r, g, b)
      @r = r.to_f
      @g = g.to_f
      @b = b.to_f
      self
    end

    def set_hsl(h, s, l)
      # h,s,l ranges are in 0.0 - 1.0
      if s.zero?
        @r = @g = @b = l
      else
        p = l <= 0.5 ? l * (1.0 + s) : l + s - (l * s)
        q = (2.0 * l) - p
        @r = hue2rgb(q, p, h + 1.0 / 3.0)
        @g = hue2rgb(q, p, h)
        @b = hue2rgb(q, p, h - 1.0 / 3.0)
      end
      self
    end

    def set_style(style)
      # rgb(255,0,0)
      if /^rgb\((\d+), ?(\d+), ?(\d+)\)$/i =~ style
        @r = [255.0, $1.to_f].min / 255.0
        @g = [255.0, $2.to_f].min / 255.0
        @b = [255.0, $3.to_f].min / 255.0
        return self
      end
      # rgb(100%,0%,0%)
      if /^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$/i =~ style
        @r = [100.0, $1.to_f].min / 100.0
        @g = [100.0, $2.to_f].min / 100.0
        @b = [100.0, $3.to_f].min / 100.0
        return self
      end
      # #ff0000
      if /^\#([0-9a-f]{6})$/i =~ style
        self.set_hex($1.hex)
        return self
      end
      # #f00
      if /^\#([0-9a-f])([0-9a-f])([0-9a-f])$/i =~ style
        self.set_hex(($1 + $1 + $2 + $2 + $3 + $3).hex)
        return self
      end
      # red
      if /^(\w+)$/i =~ style
        self.set_hex(Mittsu::ColorKeywords[style])
        return self
      end
    end

    def copy(color)
      @r = color.r
      @g = color.g
      @b = color.b
      self
    end

    def copy_gamma_to_linear(color, gamma_factor = 2.0)
      @r = color.r ** gamma_factor
      @g = color.g ** gamma_factor
      @b = color.b ** gamma_factor
      self
    end

    def copy_linear_to_gamma(color, gamma_factor = 2.0)
      safe_inverse = (gamma_factor > 0) ? (1.0 / gamma_factor) : 1.0
      @r = color.r ** safe_inverse
      @g = color.g ** safe_inverse
      @b = color.b ** safe_inverse
      self
    end

    def convert_gamma_to_linear
      rr, gg, bb = @r, @g, @b
      @r = rr * rr
      @g = gg * gg
      @b = bb * bb
      self
    end

    def convert_linear_to_gamma
      @r = Math.sqrt(@r)
      @g = Math.sqrt(@g)
      @b = Math.sqrt(@b)
      self
    end

    def hex
      (@r * 255).to_i << 16 ^ (@g * 255).to_i << 8 ^ (@b * 255).to_i << 0
    end

    def hex_string
      ('000000' + self.hex.to_s(16))[-6..-1]
    end

    def hsl(target = nil)
      # h,s,l ranges are in 0.0 - 1.0
      hsl = target || { h: 0.0, s: 0.0, l: 0.0 }
      rr, gg, bb = @r, @g, @b
      max = [r, g, b].max
      min = [r, g, b].min
      hue, saturation = nil, nil
      lightness = (min + max) / 2.0
      if min == max
        hue = 0.0
        saturation = 0.0
      else
        delta = max - min
        saturation = lightness <= 0.5 ? delta / (max + min) : delta / (2.0 - max - min)
        case max
        when rr then hue = (gg - bb) / delta + (gg < bb ? 6.0 : 0.0)
        when gg then hue = (bb - rr) / delta + 2.0
        when bb then hue = (rr - gg) / delta + 4.0
        end
        hue /= 6.0
      end
      hsl[:h] = hue
      hsl[:s] = saturation
      hsl[:l] = lightness
      hsl
    end

    def style
      "rgb(#{ (@r * 255).to_i },#{ (@g * 255).to_i },#{ (@b * 255).to_i })"
    end

    def offset_hsl(h, s, l)
      hsl = self.hsl
      hsl[:h] += h
      hsl[:s] += s
      hsl[:l] += l
      self.set_hsl(hsl[:h], hsl[:s], hsl[:l])
      self
    end

    def add(color)
      @r += color.r
      @g += color.g
      @b += color.b
      self
    end

    def add_colors(color1, color2)
      @r = color1.r + color2.r
      @g = color1.g + color2.g
      @b = color1.b + color2.b
      self
    end

    def add_scalar(s)
      @r += s
      @g += s
      @b += s
      self
    end

    def multiply(color)
      @r *= color.r
      @g *= color.g
      @b *= color.b
      self
    end

    def multiply_scalar(s)
      @r *= s
      @g *= s
      @b *= s
      self
    end

    def lerp(color, alpha)
      @r += (color.r - @r) * alpha
      @g += (color.g - @g) * alpha
      @b += (color.b - @b) * alpha
      self
    end

    def ==(c)
      (c.r == @r) && (c.g == @g) && (c.b == @b)
    end

    def []=(index, value)
      return @r = value.to_f if index == 0 || index == :r
      return @g = value.to_f if index == 1 || index == :g
      return @b = value.to_f if index == 2 || index == :b
      raise IndexError
    end

    def [](index)
      return @r if index == 0 || index == :r
      return @g if index == 1 || index == :g
      return @b if index == 2 || index == :b
      raise IndexError
    end

    def from_array(array)
      @r = array[0]
      @g = array[1]
      @b = array[2]
      self
    end

    def to_array(array = [], offset = 0)
      array[offset] = @r
      array[offset + 1] = @g
      array[offset + 2] = @b
      array
    end
    alias :to_a :to_array

    def clone
      Mittsu::Color.new(@r, @g, @b)
    end

    private

    def hue2rgb(p, q, t)
      t += 1.0 if t < 0.0
      t -= 1.0 if t > 1.0
      return p + (q - p) * 6.0 * t if t < 1.0 / 6.0
      return q if t < 1.0 / 2.0
      return p + (q - p) * 6.0 * (2.0 / 3.0 - t) if t < 2.0 / 3.0
      p
    end

  end
end
