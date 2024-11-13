module Mittsu
  class Scene
    def project(renderer)
      @renderer = renderer
      return unless visible
      project_children
    end
  end
end
