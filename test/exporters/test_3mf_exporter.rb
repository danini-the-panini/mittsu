require 'minitest_helper'
require 'rexml/document'
require 'rexml/xpath'

class Test3MFExporter < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @box = Mittsu::Mesh.new(
      Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    )
    @box.name = "box"
    @exporter = Mittsu::ThreeMFExporter.new
  end

  def test_3mf_model_file
    file = @exporter.send(:model_file, @box)
    xml = REXML::Document.new file
    assert_equal "millimeter", REXML::XPath.first(xml, "/model/@unit").value
    assert_equal "model", REXML::XPath.first(xml, "/model/resources/object/@type").value
    assert_equal 8, REXML::XPath.match(xml, "/model/resources/object/mesh/vertices/vertex").count
    assert_equal 12, REXML::XPath.match(xml, "/model/resources/object/mesh/triangles/triangle").count
  end

  def test_content_types_file
    file = @exporter.send(:content_types_file)
    xml = REXML::Document.new file
    assert_equal "application/vnd.openxmlformats-package.relationships+xml",
      REXML::XPath.first(xml, "/Types/Default[@Extension='rels']/@ContentType").value
  end

  def test_rels_file
    file = @exporter.send(:rels_file, ["box"])
    xml = REXML::Document.new file
    assert_equal "/3D/box.model",
      REXML::XPath.first(xml, "/Relationships/Relationship/@Target").value
  end

  def test_export_method_alias
    assert @exporter.parse(@box)
  end

  def teardown
    FileUtils.remove_entry @tmpdir
  end
end
