module Mittsu
  class OpenGLGroup < OpenGLObject3D
    def project
      return unless @object.visible
      project_children
    end
  end
end
