require 'mittsu/renderers/generic_lib'

module Mittsu
  module OpenGLLib
    def self.discover
      case OpenGL.get_platform
      when :OPENGL_PLATFORM_WINDOWS
        Windows.new
      when :OPENGL_PLATFORM_MACOSX
        MacOS.new
      when :OPENGL_PLATFORM_LINUX
        Linux.new
      else
        fail "Unsupported platform."
      end
    end

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
