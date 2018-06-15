module Mittsu
  class HashArray
    include Enumerable

    def initialize()
      @array = []
      @hash = {}
    end

    def [](key)
      if key.is_a? Integer
        @array[key]
      else
        @hash[key]
      end
    end

    def []=(key, value)
      if key.is_a? Integer
        @array[key] = value
      else
        @hash[key] = value
      end
    end

    def each(&block)
      @array.each(&block)
    end

    def length
      @array.length
    end
    alias_method :count, :length
    alias_method :size, :length
  end
end
