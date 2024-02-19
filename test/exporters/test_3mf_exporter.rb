require 'minitest_helper'

class Test3MFExporter < Minitest::Test
  def test_3mf_container
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
    file = exporter.parse(group)

    assert_equal file, 42
  end
end
