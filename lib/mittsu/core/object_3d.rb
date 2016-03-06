require 'securerandom'
require 'mittsu'

module Mittsu
  class Object3D
    include EventDispatcher

    attr_accessor  :name, :children, :up, :position, :rotation, :quaternion, :scale, :rotation_auto_update, :matrix, :matrix_world, :matrix_auto_update, :matrix_world_needs_update, :visible, :cast_shadow, :receive_shadow, :frustum_culled, :render_order, :user_data, :parent, :geometry

    attr_reader :id, :uuid, :type

    DefaultUp = Vector3.new(0.0, 1.0, 0.0)

    def initialize
      super
      @id = (@@id ||= 1).tap { @@id += 1 }

      @uuid = SecureRandom.uuid

      @name = ''
      @type = 'Object3D'

      @children = []

      @up = DefaultUp.clone

      @position = Vector3.new
      @rotation = Euler.new
      @quaternion = Quaternion.new
      @scale = Vector3.new(1.0, 1.0, 1.0)

      @rotation.on_change do
        @quaternion.set_from_euler(rotation, false)
      end

      @quaternion.on_change do
        @rotation.set_from_quaternion(quaternion, false)
      end

      @rotation_auto_update = true

      @matrix = Matrix4.new
      @matrix_world = Matrix4.new

      @matrix_auto_update = true
      @matrix_world_needs_update = false

      @visible = true

      @cast_shadow = false
      @receive_shadow = false

      @frustum_culled = true
      @render_order = 0

      @user_data = {}
    end

    def apply_matrix(matrix)
      @matrix.multiply_matrices(matrix, @matrix)
      @matrix.decompose(@position, @quaternion, @scale)
    end

    def set_rotation_from_axis_angle(axis, angle)
      # assumes axis is normalized
      @quaternion.set_from_axis_angle(axis, angle)
    end

    def set_rotation_from_euler(euler)
      @quaternion.set_from_euler(euler, true)
    end

    def set_rotation_from_matrix(m)
      # assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
      @quaternion.set_from_rotation_matrix(m)
    end

    def set_rotation_from_quaternion(q)
      # assumes q is normalized
      @quaternion.copy(q)
    end

    def rotate_on_axis(axis, angle)
      # rotate object on axis in object space
      # axis is assumed to be normalized
      @_q1 ||= Quaternion.new
      @_q1.set_from_axis_angle(axis, angle)
      @quaternion.multiply(@_q1)
      self
    end

    def rotate_x(angle)
      @_v1 ||= Vector3.new(1, 0, 0)
      self.rotate_on_axis(@_v1, angle)
    end

    def rotate_y(angle)
      @_v1 ||= Vector3.new(0, 1, 0)
      self.rotate_on_axis(@_v1, angle)
    end

    def rotate_z(angle)
      @_v1 ||= Vector3.new(0, 0, 1)
      self.rotate_on_axis(@_v1, angle)
    end

    def translate_on_axis(axis, distance)
      # translate object by distance along axis in object space
      # axis is assumed to be normalized
      @_v1 ||= Vector3.new
      @_v1.copy(axis).apply_quaternion(@quaternion)
      @position.add(@_v1.multiply_scalar(distance))
      self
    end

    def translate_x(distance)
      @_x_axis ||= Vector3.new(1, 0, 0)
      self.translate_on_axis(@_x_axis, distance)
    end

    def translate_y(distance)
      @_y_axis ||= Vector3.new(0, 1, 0)
      self.translate_on_axis(@_y_axis, distance)
    end

    def translate_z(distance)
      @_z_axis ||= Vector3.new(0, 0, 1)
      self.translate_on_axis(@_z_axis, distance)
    end

    def local_to_world(vector)
      vector.apply_matrix4(@matrix_world)
    end

    def world_to_local(vector)
      @_m1 ||= Matrix4.new
      vector.apply_matrix4(@_m1.get_inverse(@matrix_world))
    end

    def look_at(vector)
      # This routine does not support objects with rotated and/or translated parent(s)
      @_m1 ||= Matrix4.new
      @_m1.look_at(vector, @position, self.up)
      @quaternion.set_from_rotation_matrix(@_m1)
    end

    def add(*arguments)
      if arguments.length > 1
        arguments.each do |arg|
          self.add(arg)
        end
        return self
      end
      object = arguments.first
      if object == self
        puts("ERROR: Mittsu::Object3D#add: object can't be added as a child of itself.", object.inspect)
        return self
      end
      if object.is_a? Object3D
        object.parent.remove(object) unless object.parent.nil?
        object.parent = self
        object.dispatch_event type: :added
        @children << object
      else
        puts('ERROR: Mittsu::Object3D#add: object not an instance of Object3D.', object.inspect)
      end
      self
    end

    def remove(*arguments)
      if arguments.length > 1
        arguments.each do |arg|
          self.remove(arg)
        end
        return
      end
      object = arguments.first
      index = @children.index(object)
      if index
        object.parent = nil
        object.dispatch_event type: :removed
        @children.delete_at index
      end
      nil
    end

    def get_object_by_id(id)
      self.get_object_by_property(:id, id)
    end

    def get_object_by_name(name)
      self.get_object_by_property(:name, name)
    end

    def get_object_by_property(name, value)
      return self if self.send(name) == value
      @children.each do |child|
        object = child.get_object_by_property(name, value)
        return object unless object.nil?
      end
      nil
    end

    def get_world_position(target = Vector3.new)
      self.update_matrix_world(true)
      target.set_from_matrix_position(@matrix_world)
    end

    def get_world_quaternion(target = Quaternion.new)
      @_position ||= Vector3.new
      @_scale ||= Vector3.new
      self.update_matrix_world(true)
      @matrix_world.decompose(@_position, target, @_scale)
      target
    end

    def get_world_rotation(target = Euler.new)
      @_quaternion ||= Quaternion.new
      self.get_world_quaternion(quaternion)
      target.set_from_quaternion(quaternion, @rotation.order, false)
    end

    def get_world_scale(target = Vector3.new)
      @_position ||= Vector3.new
      @_quaternion ||= Quaternion.new
      self.update_matrix_world(true)
      @matrix_world.decompose(@_position, @_quaternion, target)
      target
    end

    def get_world_direction(target = Vector3.new)
      @_quaternion ||= Quaternion.new
      self.get_world_quaternion(@_quaternion)
      target.set(0.0, 0.0, 1.0).apply_quaternion(@_quaternion)
    end

    def raycast; end

    def traverse(&callback)
      callback.yield self
      @children.each do |child|
        child.traverse(&callback)
      end
    end

    def print_tree(lines=[])
      if lines.empty?
        puts self
      else
        last = !lines.last
        indent = lines[0..-2].map{|l| l ? '┃ ' : '  '}.join
        puts "#{indent}#{last ? '┗' : '┣'}╸#{self}"
      end
      @children.each do |child|
        child.print_tree(lines + [child != @children.last])
      end
    end

    def to_s
      "#{type} (#{name}) #{position}"
    end

    def traverse_visible(&callback)
      return unless @visible
      callback.yield self
      @children.each do |child|
        child.traverse_visible(&callback)
      end
    end

    def traverse_ancestors(&callback)
      if @parent
        callback.yielf @parent
        @parent.traverse_ancestors(&callback)
      end
    end

    def update_matrix
      @matrix.compose(@position, @quaternion, @scale)
      @matrix_world_needs_update = true
    end

    def update_matrix_world(force = false)
      self.update_matrix if @matrix_auto_update
      if @matrix_world_needs_update || force
        if @parent.nil?
          @matrix_world.copy(@matrix)
        else
          @matrix_world.multiply_matrices(@parent.matrix_world, @matrix)
        end
        @matrix_world_needs_update = false
        force = true
      end
      # update children
      @children.each do |child|
        child.update_matrix_world(force)
      end
    end

    def to_json
      @_output = {
        metadata: {
          version: 4.3,
          type: 'Object',
          generator: 'ObjectExporter'
        }
      }
      @_geometries = {}
      @_materials = {}
      @_output[:object] = self.jsonify
      @_output
    end

    def clone(object = Object3D.new, recursive = true)
      object.name = @name
      object.up.copy(@up)
      object.position.copy(@position)
      object.quaternion.copy(@quaternion)
      object.scale.copy(@scale)
      object.rotation_auto_update = @rotation_auto_update
      object.matrix.copy(@matrix)
      object.matrix_world.copy(@matrix_world)
      object.matrix_auto_update = @matrix_auto_update
      object.matrix_world_needs_update = @matrix_world_needs_update
      object.visible = @visible
      object.cast_shadow = @cast_shadow
      object.receive_shadow = @receive_shadow
      object.frustum_culled = @frustum_culled
      object.user_data = @user_data
      if recursive
        @children.each do |child|
          object.add(child.clone)
        end
      end
      object
    end

    def implementation(renderer)
      @_implementation ||= renderer.create_implementation(self)
    end

    protected

    def jsonify
      data = {}
      data[:uuid] = self.uuid
      data[:type] = self.type
      data[:name] = self.name unless self.name.nil? || self.name.empty?
      data[:user_data] = self.user_data unless self.user_data.nil? || self.user_data.empty?
      data[:visible] = self.visible unless self.visible
      data[:matrix] = self.matrix.to_a

      if !self.children.empty?
        data[:children] = []
        self.children.each do |child|
          data[:children] << child.jsonify
        end
      end

      # TODO: implement jsonify for PointCloud

      data
    end

    def jsonify_geometry(geometry)
      @_output[:geometries] ||= []
      if @_geometries[geometry.uuid].nil?
        json = geometry.to_json
        json.delete :metadata
        @_geometries[geometry.uuid] = json
        @_output[:geometries] << json
      end
      geometry.uuid
    end

    def jsonify_material(material)
      @_output[:materials] ||= []
      if @_materials[material.uuid].nil?
        json = material.to_json
        json.delete :metadata
        @_materials[material.uuid] = json
        @_output[:materials] << json
      end
      material.uuid
    end
  end
end
