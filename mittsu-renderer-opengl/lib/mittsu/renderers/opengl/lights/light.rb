module Mittsu
  class Light
    attr_accessor :camera_helper

    # def initialize(light, renderer)
    #   super
    #   @light = light
    #   @light_renderer = renderer.light_renderer
    #
    #
    #   @_direction = Vector3.new
    #   @_vector3 = Vector3.new
    # end

    def type
      self.class::TYPE
    end

    def setup(light_renderer)
      @light_renderer = light_renderer
      @cache ||= @light_renderer.cache[type]
      @cache.count += 1

      return unless visible

      @_direction ||= Vector3.new
      @_vector3 ||= Vector3.new

      setup_specific(@cache.length)

      @cache.length += 1
    end

    def project(renderer)
      @renderer = renderer
      return unless visible
      init
      # TODO!!! FIXME!!!
      @renderer.instance_variable_get(:@lights) << self
      project_children
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
