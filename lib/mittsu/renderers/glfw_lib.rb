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

  class Linux
    def initialize(loader = Linux)
      @loader = loader
    end

    def path
      return nil if file_path.nil?
      File.dirname file_path
    end

    def file
      return nil if file_path.nil?
      File.basename file_path
    end

    class << self
      def libgl_paths
        Dir.glob('/usr/lib*/**/libglfw*.so*')
      rescue
        []
      end

      def sixtyfour_bits?
        1.size == 8
      end

      def ldconfig
        `ldconfig -p | grep 'libglfw3\\?\\.so'`.lines
      rescue
        []
      end
    end

    private
      def file_path
        @_file_path ||= begin
          ldconfig_lib || sixtyfour_bit_lib || fallback_lib || give_up
        end.tap do |result|
          print_debug_info(result) if Mittsu::DEBUG
        end
      end

      def ldconfig_lib
        return nil if ldconfig.empty?
        @_debug = { source: 'ldconfig', info: ldconfig.inspect } if Mittsu::DEBUG
        ldconfig_for_arch = ldconfig.reject { |lib| @loader.sixtyfour_bits? ^ ldconfig_64?(lib) }
        ldconfig_for_arch.first.match(/=> (\/.*)$/)[1]
      end

      def ldconfig_64?(lib)
        lib =~ /\([^\)]*64[^\)]*\) =>/
      end

      def sixtyfour_bit_lib
        return nil if libs.empty?
        sixtyfour_bit_libs = libs.select { |lib| lib =~ /64/ }
        @_debug = { source: '64', info: sixtyfour_bit_libs.inspect } if Mittsu::DEBUG
        sixtyfour_bit_libs.first if @loader.sixtyfour_bits?
      end

      def fallback_lib
        return nil if libs.empty?
        @_debug = { source: 'fallback', info: libs.inspect } if Mittsu::DEBUG
        libs.first
      end

      def give_up
        @_debug = { source: 'none', info: nil } if Mittsu::DEBUG
        nil
      end

      def kernel_module
        @_kernel_module ||= @loader.kernel_module_in_use
      end

      def libs
        @_libs ||= @loader.libgl_paths.sort_by(&:length)
      end

      def ldconfig
        @_ldconfig ||= @loader.ldconfig
      end

      def print_debug_info(result)
        puts "Loading lib path: #{result.inspect}"
        puts "Source: #{@_debug[:source]}"
        puts "Info: #{@_debug[:info]}"
        puts "64-bit? #{@loader.sixtyfour_bits?}"
      end
  end

  # TODO
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
