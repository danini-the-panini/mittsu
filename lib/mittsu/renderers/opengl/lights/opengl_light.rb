module Mittsu
  class OpenGLLight < Object3D
    attr_accessor :camera_helper

    def initialize(light, renderer)
      super
      @light = light
      @light_renderer = renderer.light_renderer
      @cache = @light_renderer.cache[type]

      @_direction = Vector3.new
      @_vector3 = Vector3.new
    end

    def type
      self.class::TYPE
    end

    def setup
      @cache.count += 1

      return unless @light.visible
      setup_specific(@cache.length)

      @cache.length += 1
    end

    def project
      return unless @light.visible
      init
      # TODO!!! FIXME!!!
      @renderer.instance_variable_get(:@lights) << @light
      project_children
    end

    def setup_specific
      raise "Unknown Light Impl: #{@light.class} => #{self.class}"
    end

    def self.null_remaining_lights(cache, colors = nil)
      colors ||= cache.colors
      count = [colors.length, cache.count * 3].max
      (cache.length * 3).upto(count - 1).each { |i|
        colors[i] = 0.0
      }
    end

    def to_sym
      :other
    end
  end
end
