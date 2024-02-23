require 'builder'
require 'zip/filesystem'

module Mittsu
  class ThreeMFExporter
    def initialize(options = {})
    end

    def export(object)
      Dir.mktmpdir do |dir|
        Zip::File.open("output.3mf", Zip::File::CREATE) do |zip|
          Dir.glob("**/*", File::FNM_DOTMATCH, base: dir) do |f|
            zip.add(f, File.join(dir, f))
          end
        end
      end
      true
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
          objectIDs = []
          xml.resources do
            uuid = SecureRandom.uuid
            objectIDs << uuid
            xml.object id: uuid, type: "model" do
              xml.mesh do
                xml.vertices do
                  object.geometry.vertices.each do |vertex|
                    xml.vertex x: vertex.x, y: vertex.y, z: vertex.z
                  end
                end
                xml.triangles do
                  object.geometry.faces.each do |face|
                    xml.triangle v1: face.a, v2: face.b, v3: face.c
                  end
                end
              end
            end
          end
          xml.build do
            objectIDs.each do |id|
              xml.item objectid: id
            end
          end
        end
      end
      filename
    end
  end
end
