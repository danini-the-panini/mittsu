module Mittsu
  class BufferGeometry
    include OpenGLGeometryLike

    attr_accessor :initted

    def init
      @initted = true
    end
  end
end
