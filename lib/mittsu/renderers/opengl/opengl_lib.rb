require 'mittsu/renderers/generic_lib'

module Mittsu
  module OpenGLLib
    extend GenericLib

    class Linux < GenericLib::Linux
      def initialize(loader = Linux)
        @loader = loader
      end
    end

    class Windows
      def path; nil; end
      def file; nil; end
    end

    class MacOS
      def path; nil; end
      def file; nil; end
    end
  end
end
