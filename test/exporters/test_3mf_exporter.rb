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

  def test_3mf_exports_3d_model_part
    @exporter.send(:export_uncompressed, @tmpdir, @box)
    REXML::Document.new File.read(File.join(@tmpdir, "3D/box.model"))
    assert_equal "millimeter", REXML::XPath.first(xml, "/model/@unit").value
  end


  def test_export_method_alias
    assert @exporter.parse(Mittsu::Group.new())
  end

  def teardown
    FileUtils.remove_entry @tmpdir
  end
end
