module Mittsu
  class ThreeMFExporter
    def initialize(options = {})
    end

    def export(object)
      Dir.mktmpdir do |dir|
        export_uncompressed(dir, object)
        # TODO compress into single file
      end
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export

    private

    def export_uncompressed(dir, object)
      FileUtils.mkdir_p File.join(dir, "3D")
      export_3d_model_part(dir, object)
    end

    def export_3d_model_part(dir, object)
      filename = File.join(dir, "3D/#{object.name || SecureRandom.uuid}.model")
      File.write(filename, "ceci n'est pas une 3mf")
    end
  end
end
