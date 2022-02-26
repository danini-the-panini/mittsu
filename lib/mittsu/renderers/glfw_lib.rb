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
      SEARCH_GLOBS = ['/usr/local/lib/**',
                      '/usr/lib/**',
                      '/opt/homebrew/**']

      def path
        File.dirname(match)
      end

      def file
        File.basename(match)
      end

      private

        def match
          @match ||= find_match
        end

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
