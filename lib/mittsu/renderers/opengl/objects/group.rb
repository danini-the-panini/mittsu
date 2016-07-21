module Mittsu
  class Group
    def project(renderer)
      @renderer = renderer
      return unless visible
      project_children
    end
  end
end
