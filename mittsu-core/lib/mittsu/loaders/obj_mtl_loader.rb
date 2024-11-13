module Mittsu
  class OBJMTLLoader
    include EventDispatcher

    def initialize(manager = DefaultLoadingManager)
      @manager = manager
    end

    def load(url, mtlurl = nil)
      object = OBJLoader.new(@manager).load(url)

      if !mtlurl.nil?
        mtl_loader = MTLLoader.new(File.dirname(url))
        materials_creator = mtl_loader.load(mtlurl)

        materials_creator.preload

        object.traverse do |child_object|
          if child_object.is_a?(Mesh) && child_object.material.name && !child_object.material.name.empty?
            material = materials_creator.create(child_object.material.name)
            child_object.material = material if material
          end
        end
      end

      object
    end
  end
end
