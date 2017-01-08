require 'mittsu/renderers/generic_lib'

module Mittsu
  module GLFWLib
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

      class << self
        def libgl_paths
          Dir.glob('/usr/lib*/**/libglfw*.so*')
        rescue
          []
        end

        def ldconfig
          `ldconfig -p | grep 'libglfw3\\?\\.so'`.lines
        rescue
          []
        end
      end
    end

    class Windows
      def path; nil; end
      def file; nil; end
    end

    class MacOS
      def path
        '/usr/local/lib'
      end

      def file
        'libglfw3.dylib'
      end
    end
  end
end
