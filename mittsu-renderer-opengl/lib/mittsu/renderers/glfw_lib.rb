require 'mittsu/renderers/generic_lib'

module Mittsu
  module GLFWLib
    extend GenericLib

    class Linux < GenericLib::Linux
      def initialize(loader = Linux)
        @loader = loader
      end

      class << self
        def lib_paths
          Dir.glob('/usr/lib*/**/libglfw*.so*')
        rescue
          []
        end

        def ldconfig
          out, stderr, _status = Open3.capture3("ldconfig -p | grep 'libglfw3\\?\\.so'")
          puts stderr if DEBUG
          out.lines
        rescue
          []
        end
      end
    end

    class Windows < GenericLib::Base
      def path
        'glfw3.dll'
      end
    end

    class MacOS < GenericLib::Base
      SEARCH_GLOBS = ['/usr/local/lib/**',
                      '/usr/lib/**',
                      '/opt/homebrew/**']

      def path
        @_path ||= find_match&.to_s
      end

      private

        def find_match
          SEARCH_GLOBS.each do |glob|
            matches = Dir.glob("#{glob}/libglfw*.dylib")
            next if matches.empty?

            return matches.find { |m| m.end_with?('libglfw3.dylib') || m.end_with?('libglfw.3.dylib') } || matches.first
          end
        end
    end
  end
end
