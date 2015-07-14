require 'securerandom'

module Mittsu
  class BufferGeometry
    attr_reader :id, :name, :type, :uuid, :attributes, :draw_calls, :bounding_box, :bounding_sphere

    def initialize
      @id = (@@id ||= 1).tap { @@id += 1 }

      @uuid = SecureRandom.uuid

      @name = ''
      @type = self.class.to_s.split('::').last

      @attributes = {}

      @draw_calls = []
    end

    def attributes_keys
      @attributes.keys
    end

    def add_attribute(key, value)
      @attributes[key] = value
    end

    def get_attribute(key)
      @attributes[key]
    end

    def add_draw_call(start, count, index_offset = 0)
      @draw_calls << {
        start: start,
        count: count,
        index: index_offset,
      }
    end

    # TODO
    # def apply_matrix
    # def center
    # def from_geometry
    # def compute_bounding_box
    # def compute_bounding_sphere
    # def compute_vertex_normals
    # def compute_tangents
    # def compute_offsets
    # def merge
    # def normalize_normals
    # def reorder_buffers
    # def to_json
    # def clone
    # def dispose
  end
end
