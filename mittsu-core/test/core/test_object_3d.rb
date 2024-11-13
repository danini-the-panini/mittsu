require 'minitest_helper'

class TestObject3D < Minitest::Test
  def test_add
    object = Mittsu::Object3D.new
    child_object = Mittsu::Object3D.new

    object.add(child_object)

    assert_equal [child_object], object.children
  end

  def test_add_many
    object = Mittsu::Object3D.new
    child_object1 = Mittsu::Object3D.new
    child_object2 = Mittsu::Object3D.new
    child_object3 = Mittsu::Object3D.new

    object.add(child_object1, child_object2, child_object3)

    assert_equal [child_object1, child_object2, child_object3], object.children
  end

  def test_remove
    object = Mittsu::Object3D.new
    child_object1 = Mittsu::Object3D.new
    child_object2 = Mittsu::Object3D.new
    child_object3 = Mittsu::Object3D.new
    object.add(child_object1, child_object2, child_object3)

    object.remove(child_object2)

    assert_equal [child_object1, child_object3], object.children
  end

  def test_traverse
    object = Mittsu::Object3D.new
    child_object1 = Mittsu::Object3D.new
    child_object2 = Mittsu::Object3D.new
    grandchild_object1 = Mittsu::Object3D.new
    grandchild_object2 = Mittsu::Object3D.new
    object.add(child_object1, child_object2)
    child_object1.add(grandchild_object1, grandchild_object2)

    all_objects = []
    object.traverse do |obj|
      all_objects << obj
    end

    assert_equal [
      object,
      child_object1,
      grandchild_object1,
      grandchild_object2,
      child_object2
    ], all_objects
  end

  def test_traverse_visible
    object = Mittsu::Object3D.new
    child_object1 = Mittsu::Object3D.new
    child_object2 = Mittsu::Object3D.new
    grandchild_object1 = Mittsu::Object3D.new
    grandchild_object2 = Mittsu::Object3D.new
    grandchild_object3 = Mittsu::Object3D.new
    object.add(child_object1, child_object2)
    child_object1.add(grandchild_object1, grandchild_object2)
    child_object2.add(grandchild_object3)

    child_object2.visible = false
    grandchild_object1.visible = false

    all_objects = []
    object.traverse_visible do |obj|
      all_objects << obj
    end

    assert_equal [
      object,
      child_object1,
      grandchild_object2
    ], all_objects
  end

  def test_traverse_ancestors
    object = Mittsu::Object3D.new
    object.add(child_object = Mittsu::Object3D.new)
    child_object.add(grandchild_object = Mittsu::Object3D.new)
    grandchild_object.add(great_grandchild_object = Mittsu::Object3D.new)

    all_objects = []
    great_grandchild_object.traverse_ancestors do |obj|
      all_objects << obj
    end

    assert_equal [
      grandchild_object,
      child_object,
      object
    ], all_objects
  end

  def test_traverse_ancestors_with_not_parent
    object = Mittsu::Object3D.new

    all_objects = []
    object.traverse_ancestors do |obj|
      all_objects << obj
    end

    assert_empty all_objects
  end

  def test_to_json
    object = Mittsu::Object3D.new

    assert_equal({
      metadata: {
        version: 4.3,
        type: 'Object',
        generator: 'ObjectExporter'
      },
      object: {
        uuid: object.uuid,
        type: 'Object3D',
        matrix: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
      }
    }, object.to_json)
  end

  def test_to_json_with_children
    object = Mittsu::Object3D.new
    object.add(child = Mittsu::Object3D.new)

    assert_equal({
      metadata: {
        version: 4.3,
        type: 'Object',
        generator: 'ObjectExporter'
      },
      object: {
        uuid: object.uuid,
        type: 'Object3D',
        matrix: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0],
        children: [{
          uuid: child.uuid,
          type: 'Object3D',
          matrix: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0],
        }]
      }
    }, object.to_json)
  end

  def test_clone
    object = Mittsu::Object3D.new
    object.name = 'Foo'
    object.position = Mittsu::Vector3.new(4, 5, 6)

    cloned = object.clone

    assert_equal 'Foo', cloned.name
    assert_equal Mittsu::Vector3.new(4, 5, 6), cloned.position

    refute_equal object, cloned
  end

  def test_clone_with_passed_object
    object = Mittsu::Object3D.new
    object.name = 'Foo'
    object.position = Mittsu::Vector3.new(4, 5, 6)

    other_object = Mittsu::Object3D.new
    cloned = object.clone other_object

    assert_equal 'Foo', cloned.name
    assert_equal Mittsu::Vector3.new(4, 5, 6), cloned.position

    assert_equal other_object, cloned
    refute_equal object, cloned
  end

  def test_clone_with_children
    object = Mittsu::Object3D.new
    object.name = 'Foo'
    object.position = Mittsu::Vector3.new(1, 2, 3)

    object.add(child = Mittsu::Object3D.new)
    child.name = 'Bar'
    child.position = Mittsu::Vector3.new(4, 5, 6)

    cloned = object.clone

    assert_equal 'Foo', cloned.name
    assert_equal Mittsu::Vector3.new(1, 2, 3), cloned.position
    assert_equal 1, cloned.children.count

    cloned_child = cloned.children.first

    assert_equal 'Bar', cloned_child.name
    assert_equal Mittsu::Vector3.new(4, 5, 6), cloned_child.position

    refute_equal object, cloned
    refute_equal child, cloned_child
  end

  def test_clone_with_children_not_recursive
    object = Mittsu::Object3D.new
    object.name = 'Foo'
    object.position = Mittsu::Vector3.new(1, 2, 3)

    object.add(child = Mittsu::Object3D.new)
    child.name = 'Bar'
    child.position = Mittsu::Vector3.new(4, 5, 6)

    cloned = object.clone(nil, false)

    assert_equal 'Foo', cloned.name
    assert_equal Mittsu::Vector3.new(1, 2, 3), cloned.position
    assert_empty cloned.children
  end
end
