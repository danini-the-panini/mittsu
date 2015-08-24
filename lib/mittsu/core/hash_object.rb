module Mittsu
  class HashObject
    def initialize
      @_hash = {}
    end

    def [](key)
      @_hash[key]
    end

    def []=(key, value)
      @_hash[key] = value
    end

    def delete(key)
      @_hash.delete(key)
    end
  end
end
