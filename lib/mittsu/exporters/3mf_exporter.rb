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
      export_content_types(dir)
      filename = export_3d_model_part(dir, object)
      export_rels(dir, [filename])
    end

    def export_content_types(dir)
      filename = File.join(dir, "[Content_Types].xml")
      File.open(filename, "wb") do |file|
        xml = Builder::XmlMarkup.new(target: file, indent: 2)
        xml.instruct! :xml, encoding: "UTF-8"
        xml.Types xmlns: "http://schemas.openxmlformats.org/package/2006/content-types" do
          xml.Default Extension: "rels", ContentType: "application/vnd.openxmlformats-package.relationships+xml"
          xml.Default Extension: "model", ContentType: "application/vnd.ms-package.3dmanufacturing-3dmodel+xml"
        end
      end
    end

    def export_rels(dir, models)
      FileUtils.mkdir_p File.join(dir, "_rels")
      filename = File.join(dir, "_rels/.rels")
      File.open(filename, "wb") do |file|
        xml = Builder::XmlMarkup.new(target: file, indent: 2)
        xml.instruct! :xml, encoding: "UTF-8"
        xml.Relationships xmlns: "http://schemas.openxmlformats.org/package/2006/relationships" do
          models.each do |name|
            xml.Relationship Target: "/3D/#{name}.model", Id: name, ContentType: "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"
          end
        end
      end
    end

    def export_3d_model_part(dir, object)
      FileUtils.mkdir_p File.join(dir, "3D")
      filename = object.name.parameterize || SecureRandom.uuid
      pathname = File.join(dir, "3D/#{filename}.model")
      File.open(pathname, "wb") do |file|
        xml = Builder::XmlMarkup.new(target: file, indent: 2)
        xml.instruct! :xml, encoding: "UTF-8"
        xml.model unit: "millimeter", "xml:lang": "en-US", xmlns:"http://schemas.microsoft.com/3dmanufacturing/core/2015/02" do

        end
      end
      filename
    end
  end
end
