module Mittsu
  class Sprite
    def project(renderer)
      @renderer = renderer
      return unless visible
      init
      # TODO!!! FIXME!!!
      @renderer.instance_variable_get(:@sprites) << self
      project_children
    end
  end
end
