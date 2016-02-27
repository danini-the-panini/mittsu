require 'securerandom'
require 'mittsu'
require 'mittsu/core/hash_object'

module Mittsu
  class Material < HashObject
    include EventDispatcher

    attr_reader :id, :uuid, :type

    attr_accessor :name, :side, :opacity, :transparent, :blending, :blend_src, :blend_dst, :blend_equation, :blend_src_alpha, :blend_dst_alpha, :blend_equation_alpha, :depth_test, :depth_write, :color_write, :polygon_offset, :polygon_offset_factor, :polygon_offset_units, :alpha_test, :overdraw, :visible, :attributes, :shading, :program

    attr_accessor :map, :env_map, :light_map, :light_map, :normal_map, :specular_map, :alpha_map, :combine, :vertex_colors, :fog, :size_attenuation, :skinning, :morph_targets, :morph_normals, :metal, :wrap_around, :defines, :lights, :color, :bump_map, :reflectivity, :refraction_ratio, :wireframe, :default_attribute_values, :uniforms, :vertex_shader, :fragment_shader

    def initialize
      super
      @id = (@@id ||= 1).tap { @@id += 1 }

      @uuid = SecureRandom.uuid

      @name = ''
      @type = 'Material'

      @side = FrontSide

      @opacity = 1.0
      @transparent = false

      @blending = NormalBlending

      @blend_src = SrcAlphaFactor
      @blend_dst = OneMinusSrcAlphaFactor
      @blend_equation = AddEquation
      @blend_src_alpha = nil
      @blend_dst_alpha = nil
      @blend_equation_alpha = nil

      @depth_test = true
      @depth_write = true

      @color_write = true

      @polygon_offset = false
      @polygon_offset_factor = 0
      @polygon_offset_units = 0

      @alpha_test = 0

      # TODO: remove this maybe???
      @overdraw = 0 # Overdrawn pixels (typically between 0 and 1) for fixing antialiasing gaps in CanvasRenderer

      @visible = true

      @_needs_update = true
    end

    def needs_update?
      @_needs_update
    end

    def needs_update=(value)
      update if value
      @_needs_update = value
    end

    def set_values(values = nil)
      return if values.nil?

      values.each do |(key, new_value)|
        if new_value.nil?
          puts "WARNING: Mittsu::Material: #{key} parameter is undefined"
          next
        end

        if has_property? key
          current_value = get_property(key)

          if current_value.is_a? Color
            current_value.set(new_value)
          elsif current_value.is_a?(Vector3) && new_value.is_a?(Vector3)
            current_value.copy(new_value)
          else
            set_property(key, new_value)
          end
        end
      end
    end

    def to_json
      output = {
        metadata: {
          version: 4.2,
          type: 'material',
          generator: 'MaterialExporter'
        },
        uuid: @uuid,
        type: @type
      }

      output[:name] = @name if !@name.nil? && !@name.empty?

      output[:opacity] = @opacity if @opacity < 1.0
      output[:transparent] = @transparent if @transparent
      output[:wireframe] = @wireframe if @wireframe
      output
    end

    def clone(material = Material.new)
      material.name = @name
      material.side = @side
      material.opacity = @opacity
      material.transparent = @transparent
      material.blending = @blending
      material.blend_src = @blend_src
      material.blend_dst = @blend_dst
      material.blend_equation = @blend_equation
      material.blend_src_alpha = @blend_src_alpha
      material.blend_dst_alpha = @blend_dst_alpha
      material.blend_equation_alpha = @blend_equation_alpha
      material.depth_test = @depth_test
      material.depth_write = @depth_write
      material.color_write = @color_write
      material.polygon_offset = @polygon_offset
      material.polygon_offset_factor = @polygon_offset_factor
      material.polygon_offset_units = @polygon_offset_units
      material.alpha_test = @alpha_test
      material.overdraw = @overdraw
      material.visible = @visible
    end

    def update
      dispatch_event type: :update
    end

    def dispose
      dispatch_event type: :dispose
    end

    def implementation(renderer)
      @_implementation ||= renderer.create_material_implementation(self)
    end

    private

    def has_property?(key)
      sym = "@#{key}".to_sym
      self.instance_variable_defined?(sym)
    end

    def set_property(key, value)
      sym = "@#{key}".to_sym
      self.instance_variable_set(sym, value)
    end

    def get_property(key)
      sym = "@#{key}".to_sym
      self.instance_variable_get(sym)
    end
  end
end
