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
      def kernel_module_in_use
        lspci_line = `lspci -nnk | grep -i vga -A3 | grep 'in use'`
        /in use:\s*(\S+)/ =~ lspci_line && $1
      end

      def libgl_paths
        Dir.glob('/usr/lib*/**/libGL.so')
      end

      def sixtyfour_bits?
        1.size == 8
      end
    end

    private
      def file_path
        @_file_path ||= begin
          return nil if libs.size == 0
          driver_specific_lib || sixtyfour_bit_lib || libs.first
        end
      end

      def driver_specific_lib
        libs.grep(/nvidia/).first if kernel_module =~ /nvidia/
      end

      def sixtyfour_bit_lib
        libs.grep(/64/).first if @loader.sixtyfour_bits?
      end

      def kernel_module
        @_kernel_module ||= @loader.kernel_module_in_use
      end

      def libs
        @_libs ||= @loader.libgl_paths.sort_by(&:length)
      end
  end

  # TODO
  class Windows
    def path; nil; end
    def file; nil; end
  end

  # TODO
  class MacOS
    def path; nil; end
    def file; nil; end
  end
end
