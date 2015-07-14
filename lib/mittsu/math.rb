module Math
  def self.sign(x)
    return Float::NAN unless x.is_a? Numeric
    return Float::NAN if x.to_f.nan?
    return x.to_f if x.zero?
    return (x < 0) ? -1.0 : (x > 0) ? 1.0 : +x
  end
end
