module Mittsu
  class ThreeMFExporter
    def initialize(options = {})
    end

    def export(object)
      export_uncompressed(object)
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export

    private

    def export_uncompressed(object)
      "ceci n'est pas une 3mf"
    end
  end
end
