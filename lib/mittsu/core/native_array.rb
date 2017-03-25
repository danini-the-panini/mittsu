require 'fiddle'

module Mittsu
  class NativeArray
    FREEFUNC = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    include Enumerable

    attr_reader :size
    alias count size
    alias length size

    def initialize(size)
      @size = size
      @ptr = Fiddle::Pointer.malloc(size * self.class::SIZEOF_ELEMENT, FREEFUNC)
    end

    def [](index, length=nil)
      if length.nil?
        @ptr[index * self.class::SIZEOF_ELEMENT, self.class::SIZEOF_ELEMENT].unpack(self.class::PACK_DIRECTIVE)[0]
      else
        @ptr[index * self.class::SIZEOF_ELEMENT, length * self.class::SIZEOF_ELEMENT].unpack("#{self.class::PACK_DIRECTIVE}#{length}")
      end
    end

    def []=(index, length=nil, value)
      if length.nil?
        @ptr[index * self.class::SIZEOF_ELEMENT, self.class::SIZEOF_ELEMENT] = [value].pack(self.class::PACK_DIRECTIVE)
      else
        string = value.is_a?(Array) ? value.pack("#{self.class::PACK_DIRECTIVE}#{length}") : value
        @ptr[index * self.class::SIZEOF_ELEMENT, length * self.class::SIZEOF_ELEMENT] = string
      end
    end

    def each
      return enum_for(:each) unless block_given?

      @size.times do |index|
        yield self[index]
      end
    end

    def to_a
      each.to_a
    end
    alias to_ary to_a

    def to_s
      to_a.to_s
    end

    def dup
      self.class.new(length).tap do |array|
        array[0, length] = self[0, length]
      end
    end

    def self.from_array(array, length = nil)
      length ||= array.length
      from_string(array.pack("#{self::PACK_DIRECTIVE}#{length}"), length)
    end

    def self.from_string(string, length = nil)
      length ||= string.bytesize / self::SIZEOF_ELEMENT
      new(length).tap do |array|
        array[0, length] = string
      end
    end
  end

  class Float32Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_FLOAT
    PACK_DIRECTIVE = 'F'
  end

  class Int32Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_INT
    PACK_DIRECTIVE = 'l'
  end

  class Int16Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_SHORT
    PACK_DIRECTIVE = 's'
  end

  class Int8Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_CHAR
    PACK_DIRECTIVE = 'c'
  end

  class UInt32Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_INT
    PACK_DIRECTIVE = 'L'
  end

  class UInt16Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_SHORT
    PACK_DIRECTIVE = 'S'
  end

  class UInt8Array < NativeArray
    SIZEOF_ELEMENT = Fiddle::SIZEOF_CHAR
    PACK_DIRECTIVE = 'C'
  end
end
