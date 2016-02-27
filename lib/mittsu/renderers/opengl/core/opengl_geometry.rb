require 'mittsu/renderers/opengl/opengl_geometry_like'

module Mittsu
  class OpenGLGeometry
    include OpenGLGeometryLike

    attr_accessor :groups
    attr_reader :id

    def initialize(geometry, renderer)
      @id = (@@id ||= 1).tap { @@id += 1 }

      @geometry = geometry
      @renderer = renderer
    end
  end
end
