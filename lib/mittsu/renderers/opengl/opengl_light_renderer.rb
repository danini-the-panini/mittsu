module Mittsu
  class OpenGLLightRenderer
    attr_accessor :lights_need_update, :cache

    LIGHT_CLASSES = [
      AmbientLight,
      DirectionalLight,
      PointLight,
      SpotLight,
      HemisphereLight
    ]
    LIGHT_TYPES = LIGHT_CLASSES.map { |klass| klass::TYPE }

    def initialize(renderer)
      @renderer = renderer
      @lights_need_update = true
      @cache = {}
      LIGHT_CLASSES.each { |klass|
        @cache[klass::TYPE] = klass::Cache.new
      }
    end

    def setup(lights)
      @cache.values.each(&:reset)

      lights.each do |light|
        next if light.only_shadow
        light.setup(self)
      end

      LIGHT_CLASSES.each do |klass|
        cache = @cache[klass::TYPE]
        klass.null_remaining_lights(cache)
      end

      @lights_need_update = false
    end

    def reset
      @lights_need_update = true
    end
  end
end
