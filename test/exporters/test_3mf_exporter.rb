require 'minitest_helper'

class Test3MFExporter < Minitest::Test
  def test_3mf_content
    # Create a test object
    box = Mittsu::Mesh.new(
      Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    )
    obj = Mittsu::Object3D.new
    obj.add(box)
    group = Mittsu::Group.new
    group.add obj

    # Export to 3MF
    exporter = Mittsu::ThreeMFExporter.new
    file = exporter.send(:export_uncompressed, group)

    assert_equal file, 42
  end

  def test_export_method_alias
    exporter = Mittsu::ThreeMFExporter.new
    result = exporter.parse(Mittsu::Group.new())
    assert_kind_of(String, result)
  end
end
