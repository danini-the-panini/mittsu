class Minitest::Test
  DELTA = 0.000000000001

  def x; 2; end
  def y; 3; end
  def z; 4; end
  def w; 5; end

  def negInf2
    @_negInf2 ||= Mittsu::Vector2.new(-Float::INFINITY, -Float::INFINITY)
  end
  def posInf2
    @_posInf2 ||= Mittsu::Vector2.new(Float::INFINITY, Float::INFINITY)
  end

  def zero2
    @_zero2 ||= Mittsu::Vector2.new
  end
  def one2
    @_one2 ||= Mittsu::Vector2.new(1, 1)
  end
  def two2
    @_two2 ||= Mittsu::Vector2.new(2, 2)
  end

  def negInf3
    @_negInf3 ||= Mittsu::Vector3.new(-Float::INFINITY, -Float::INFINITY, -Float::INFINITY)
  end
  def posInf3
    @_posInf3 ||= Mittsu::Vector3.new(Float::INFINITY, Float::INFINITY, Float::INFINITY)
  end

  def zero3
    @_zero3 ||= Mittsu::Vector3.new()
  end
  def one3
    @_one3 ||= Mittsu::Vector3.new(1, 1, 1)
  end
  def two3
    @_two3 ||= Mittsu::Vector3.new(2, 2, 2)
  end
end
