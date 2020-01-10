require 'mittsu/renderers/generic_lib'

module Mittsu
  module GLFWLib
    extend GenericLib

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

    class Windows < GenericLib::Base
    end

    class MacOS < GenericLib::Base
      def path
        '/usr/local/lib'
      end

      def file
        matches = Dir.glob('/usr/local/lib/libglfw*.dylib').map { |path| File.basename(path) }
        return matches.find { |m| m == 'libglfw3.dylib' || m == 'libglfw.3.dylib' } || matches.first
      end
    end
  end
end
