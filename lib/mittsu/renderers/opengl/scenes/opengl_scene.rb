module Mittsu
  class OpenGLScene < OpenGLObject3D
    def project
      return unless @object.visible
      project_children
    end
  end
end
