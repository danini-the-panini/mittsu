module Mittsu
  module GenericLib
    def discover
      case OpenGL.get_platform
      when :OPENGL_PLATFORM_WINDOWS
        self::Windows.new
      when :OPENGL_PLATFORM_MACOSX
        self::MacOS.new
      when :OPENGL_PLATFORM_LINUX
        self::Linux.new
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

      class << self
        def kernel_module_in_use
          lspci_line = `lspci -nnk | grep -i vga -A3 | grep 'in use'`
          /in use:\s*(\S+)/ =~ lspci_line && $1
        rescue
          ''
        end

        def libgl_paths
          Dir.glob('/usr/lib*/**/libGL.so*')
        rescue
          []
        end

        def sixtyfour_bits?
          1.size == 8
        end

        def ldconfig
          `ldconfig -p | grep 'libGL\\.so'`.lines
        rescue
          []
        end
      end

      private
        def file_path
          @_file_path ||= begin
            ldconfig_lib || driver_specific_lib || sixtyfour_bit_lib || fallback_lib || give_up
          end.tap do |result|
            print_debug_info(result) if DEBUG
          end
        end

        def ldconfig_lib
          return nil if ldconfig.empty?
          @_debug = { source: 'ldconfig', info: ldconfig.inspect } if DEBUG
          ldconfig_for_arch = ldconfig.reject { |lib| @loader.sixtyfour_bits? ^ ldconfig_64?(lib) }
          ldconfig_for_arch.first.match(/=> (\/.*)$/)[1]
        end

        def ldconfig_64?(lib)
          lib =~ /\([^\)]*64[^\)]*\) =>/
        end

        def driver_specific_lib
          return nil if libs.empty?
          @_debug = { source: 'driver', info: kernel_module } if DEBUG
          libs.select { |lib| lib =~ /nvidia/ }.first if kernel_module =~ /nvidia/
        end

        def sixtyfour_bit_lib
          return nil if libs.empty?
          sixtyfour_bit_libs = libs.select { |lib| lib =~ /64/ }
          @_debug = { source: '64', info: sixtyfour_bit_libs.inspect } if DEBUG
          sixtyfour_bit_libs.first if @loader.sixtyfour_bits?
        end

        def fallback_lib
          return nil if libs.empty?
          @_debug = { source: 'fallback', info: libs.inspect } if DEBUG
          libs.first
        end

        def give_up
          @_debug = { source: 'none', info: nil } if DEBUG
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
  end
end
