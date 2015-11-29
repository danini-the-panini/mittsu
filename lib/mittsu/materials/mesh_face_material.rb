require 'securerandom'

module Mittsu
  class MeshFaceMaterial
    def initialize(materials = [])
      @uuid = SecureRandom.uuid
      @type = 'MeshFaceMaterial'
      @materials = materials
    end

    def to_json
      {
        metadata: {
          version: 4.2,
          type: 'material',
          generator: 'MaterialExporter'
        },
        uuid: @uuid,
        type: @type,
        materials: @materials.map(&:to_json)
      }
    end

    def clone
      MeshFaceMaterial.new.tap do |mateiral|
        material.materials = @materials.map(&:clone)
      end
    end
  end
end
