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
      # http://www.pilotlogic.com/sitejoom/index.php/wiki?id=398<F37>
      # 32              64
      # /usr/lib        /usr/lib64       redhat, mandriva
      # /usr/lib32      /usr/lib64       arch, gento
      # /usr/lib        /usr/lib64       slackware
      # /usr/lib/i386.. /usr/libx86_64/  debian
      libs = Dir.glob("/usr/lib*/**/libGL.so")
      if libs.size == 0
        puts "no libGL.so"
        exit 1
      end
      case kernel_module_in_use
      when /nvidia/
        return File.dirname(libs.grep(/nvidia/)[0])
      end
      # Get the same architecture that the runnning ruby
      if 1.size == 8 # 64 bits
        File.dirname(libs.grep(/64/)[0])
      else # 32 bits
        File.dirname(libs[0])
      end
    end

    def file
      'libGL.so'
    end

    private
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
