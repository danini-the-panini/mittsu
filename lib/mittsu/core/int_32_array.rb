require 'fiddle'

module Mittsu
  class Int32Array
    FREEFUNC = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    include Enumerable

    attr_reader :size
    alias count size
    alias length size

    def initialize(size)
      @size = size
      @ptr = Fiddle::Pointer.malloc(size * Fiddle::SIZEOF_INT, FREEFUNC)
    end

    def [](index, length=nil)
      if length.nil?
        @ptr[index * Fiddle::SIZEOF_INT, Fiddle::SIZEOF_INT].unpack('l')[0]
      else
        @ptr[index * Fiddle::SIZEOF_INT, length * Fiddle::SIZEOF_INT].unpack("l#{length}")
      end
    end

    def []=(index, length=nil, value)
      if length.nil?
        @ptr[index * Fiddle::SIZEOF_INT, Fiddle::SIZEOF_INT] = [value].pack('l')
      else
        string = value.is_a?(Array) ? value.pack("l#{length}") : value
        @ptr[index * Fiddle::SIZEOF_INT, length * Fiddle::SIZEOF_INT] = string
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
      from_string(array.pack("l#{length}"), length)
    end

    def self.from_string(string, length = nil)
      length ||= string.bytesize / Fiddle::SIZEOF_INT
      new(length).tap do |array|
        array[0, length] = string
      end
    end
  end
end
