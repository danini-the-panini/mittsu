require 'mittsu'

module Mittsu
  class Scene < Object3D

    attr_accessor :fog, :override_material, :auto_update

    def initialize
      super

      @type = 'Scene'

      @auto_update = true
    end

    def clone(object = Scene.new)
      super

      object.fog = fog unless fog.nil?
      object.override_material = override_material unless override_material.nil?

      object.auto_update = auto_update
      object.matrix_auto_update = matrix_auto_update
      object
    end
  end
end
