module Mittsu
  class OpenGLAmbientLight < OpenGLLight
    TYPE = :ambient

    class Cache < Struct.new(:length, :count, :value)
      def initialize
        super(0, 0, [0.0, 0.0, 0.0])
      end

      def reset
        self.length = 0
        self.value[0] = 0.0
        self.value[1] = 0.0
        self.value[2] = 0.0
      end
    end

    def setup_specific(_)
      @cache.value[0] += @light.color.r
      @cache.value[1] += @light.color.g
      @cache.value[2] += @light.color.b
    end

    def self.null_remaining_lights(_); end
  end
end
