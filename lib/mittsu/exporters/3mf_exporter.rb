require 'builder'

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
      File.open(filename, "wb") do |file|
        xml = Builder::XmlMarkup.new(target: file, indent: 2)
        xml.instruct! :xml, encoding: "UTF-8"
        xml.model unit: "millimeter", "xml:lang": "en-US", xmlns:"http://schemas.microsoft.com/3dmanufacturing/core/2015/02" do

        end
      end
    end
  end
end
