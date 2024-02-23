require 'builder'
require 'zip/filesystem'

module Mittsu
  class ThreeMFExporter
    def initialize(options = {})
    end

    def export(object, filename)
      Zip::OutputStream.open(filename) do |zip|
        # OPC content types file
        store(zip, "[Content_Types].xml", content_types_file)
        # Add models
        models = [object]
        model_names = models.map do |model|
          # Set a model name if there isn't one
          model.name ||= SecureRandom.uuid
          # Make model name filesystem-safe
          name = model.name.parameterize
          # Store model
          store(zip, "3D/#{name}.model", model_file(model))
          # Remember the name for later
          name
        end
        # Add OPC rels file with list of contained models
        store(zip, "_rels/.rels", rels_file(model_names))
      end
      true
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export

    private

    def store(zip, filename, data)
      zip.put_next_entry(filename)
      zip.write(data)
    end

    def build &block
      xml = Builder::XmlMarkup.new
      xml.instruct! :xml, encoding: "UTF-8"
      yield xml
      xml.target!
    end

    def content_types_file
      build do |xml|
        xml.Types xmlns: "http://schemas.openxmlformats.org/package/2006/content-types" do
          xml.Default Extension: "rels", ContentType: "application/vnd.openxmlformats-package.relationships+xml"
          xml.Default Extension: "model", ContentType: "application/vnd.ms-package.3dmanufacturing-3dmodel+xml"
        end
      end
    end

    def rels_file(models)
      build do |xml|
        xml.Relationships xmlns: "http://schemas.openxmlformats.org/package/2006/relationships" do
          models.each do |name|
            xml.Relationship Target: "/3D/#{name}.model", Id: name, ContentType: "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"
          end
        end
      end
    end

    def model_file(object)
      build do |xml|
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
    end
  end
end
