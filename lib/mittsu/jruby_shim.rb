
BEGIN {
  puts "CHECKING FOR JRUBY SHIM REQUIREMENT: #{RUBY_PLATFORM}"
  if RUBY_PLATFORM == 'java'
    puts "APPLYING JRUBY SHIM"
    require 'fiddle'

    # See https://github.com/jruby/jruby/issues/3462
    require 'mittsu/jruby_shim/libc'

    # See https://github.com/jruby/jruby/issues/3477
    MISSING_CONSTANTS = {
      TYPE_SIZE_T:       -5,
      TYPE_SSIZE_T:      5,
      TYPE_PTRDIFF_T:    5,
      TYPE_INTPTR_T:     5,
      TYPE_UINTPTR_T:    -5,

      ALIGN_SIZE_T:      Fiddle::ALIGN_VOIDP,
      ALIGN_SSIZE_T:     Fiddle::ALIGN_VOIDP,
      ALIGN_PTRDIFF_T:   Fiddle::ALIGN_VOIDP,
      ALIGN_INTPTR_T:    Fiddle::ALIGN_VOIDP,
      ALIGN_UINTPTR_T:   Fiddle::ALIGN_VOIDP,

      SIZEOF_SIZE_T:     Fiddle::SIZEOF_VOIDP,
      SIZEOF_SSIZE_T:    Fiddle::SIZEOF_VOIDP,
      SIZEOF_PTRDIFF_T:  Fiddle::SIZEOF_VOIDP,
      SIZEOF_INTPTR_T:   Fiddle::SIZEOF_VOIDP,
      SIZEOF_UINTPTR_T:  Fiddle::SIZEOF_VOIDP,

      LibC:              FFI::LibC
    }

    MISSING_CONSTANTS.each do |(name, value)|
      Fiddle.const_set(name, value) unless Fiddle.const_defined?(name)
    end

    module Fiddle
      class Pointer
        def [](index, length = nil)
          if length
            ffi_ptr.get_bytes(index, length)
          else
            ffi_ptr.get_int8(index)
          end
        rescue FFI::NullPointerError
          raise DLError.new('NULL pointer dereference')
        end

        def []=(index, length = nil, value)
          if length
            if value.is_a?(Integer)
              value_str = Pointer.new(value).to_s
            else
              value_str = value.to_str
            end
            ffi_ptr.put_bytes(index, value_str, 0, [length, value_str.bytesize].min)
          else
            ffi_ptr.put_int8(index, value)
          end
        rescue FFI::NullPointerError
          raise DLError.new('NULL pointer dereference')
        end
      end
    end
  end
}
