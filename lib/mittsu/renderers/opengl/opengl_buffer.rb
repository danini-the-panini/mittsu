module Mittsu
  class OpenGLBuffer < Struct.new(:buffer, :object, :material, :z)
    attr_accessor :render, :transparent, :opaque
  end
end
