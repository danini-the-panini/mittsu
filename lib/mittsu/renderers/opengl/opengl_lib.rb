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
    def path
      return nil if file_path.nil?
      File.dirname file_path
    end

    def file
      return nil if file_path.nil?
      File.basename file_path
    end

    private
      def file_path
        @_file_path ||= begin
          libs = Dir.glob("/usr/lib*/**/libGL.so*")
          if libs.size == 0
            puts "no libGL.so"
            exit 1
          end
          case kernel_module_in_use
          when /nvidia/
            return libs.grep(/nvidia/)[0]
          end
          if 1.size == 8 # 64 bits
            libs.grep(/64/)[0]
          else # 32 bits
            libs[0]
          end
        end.tap { |x| puts x }
      end

      def kernel_module_in_use
        lspci_line = `lspci -nnk | grep -i vga -A3 | grep 'in use'`
        return /in use:\s*(\S+)/ =~ lspci_line && $1
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
