module Mittsu
  class OpenGLMaterial
    # TODO: init_shader for these material-types
    # MeshDepthMaterial => :depth, # TODO...
    # MeshNormalMaterial => :normal, # TODO...
    # LineDashedMaterial => :dashed, # TODO...
    # PointCloudMaterial => :particle_basic # TODO...

    attr_accessor :shadow_pass
    attr_reader :shader, :uniforms_list

    def initialize(material, renderer)
      @material = material
      @renderer = renderer
    end

    def init(lights, fog, object)
      @material.add_event_listener(:dispose, @renderer.method(:on_material_dispose))

      init_shader

      @material.program = find_or_create_program(lights, fog, object)

      count_supported_morph_attributes(@material.program.attributes)

      @uniforms_list = get_uniforms_list
    end

    def set
      if @material.transparent
        @renderer.state.set_blending(@material.blending, @material.blend_equation, @material.blend_src, @material.blend_dst, @material.blend_equation_alpha, @material.blend_src_alpha, @material.blend_dst_alpha)
      else
        @renderer.state.set_blending(NoBlending)
      end

      @renderer.state.set_depth_test(@material.depth_test)
      @renderer.state.set_depth_write(@material.depth_write)
      @renderer.state.set_color_write(@material.color_write)
      @renderer.state.set_polygon_offset(@material.polygon_offset, @material.polygon_offset_factor, @material.polygon_offset_units)
    end

    def needs_face_normals?
      @material.shading == FlatShading
    end

    def clear_custom_attributes
      @material.attributes.each do |attribute|
        attribute.needs_update = false
      end
    end

    def custom_attributes_dirty?
      @material.attributes.each do |attribute|
        return true if attribute.needs_update
      end
      false
    end

    def refresh_uniforms(_)
      # NOOP
    end

    def needs_camera_position_uniform?
      @material.env_map
    end

    def needs_view_matrix_uniform?
      @material.skinning
    end

    def needs_lights?
      @material.lights
    end

    protected

    def init_shader
      @shader = {
        uniforms: @material.uniforms,
        vertex_shader: @material.vertex_shader,
        fragment_shader: @material.fragment_shader
      }
    end

    def shader_id
      nil
    end

    private

    def allocate_lights(lights)
      lights.reject { |light|
        light.only_shadow || !light.visible
      }.each_with_object({
        directional: 0, point: 0, spot: 0, hemi: 0, other: 0
      }) { |light, counts|
        counts[light.implementation(@renderer).to_sym] += 1
      }
    end

    def allocate_shadows(lights)
      max_shadows = 0

      lights.each do |light|
        next unless light.cast_shadow

        max_shadows += 1 if light.is_a?(SpotLight)
        max_shadows += 1 if light.is_a?(DirectionalLight) && !light.shadow_cascade
      end

      max_shadows
    end

    def allocate_bones(object = nil)
      if @renderer.supports_bone_textures? && object && object.skeleton && object.skeleton.use_vertex_texture
        return 1024
      end

      # default for when object is not specified
      # ( for example when prebuilding shader
      #   to be used with multiple objects )
      #
      #  - leave some extra space for other uniforms
      #  - limit here is ANGLE's 254 max uniform vectors
      #    (up to 54 should be safe)

      n_vertex_uniforms = (glGetParameter(GL_MAX_VERTEX_UNIFORM_COMPONENTS) / 4.0).floor
      n_vertex_matrices = ((n_vertex_uniforms - 20) / 4.0).floor

      max_bones = n_vertex_matrices

      # TODO: when SkinnedMesh exists
      # if !object.nil? && object.is_a?(SkinnedMesh)
      #   max_bones = [object.skeleton.bones.length, max_bones].min
      #
      #   if max_bones < object.skeleton.bones.length
      #     puts "WARNING: OpenGLRenderer: too many bones - #{object.skeleton.bones.length}, this GPU supports just #{max_bones}"
      #   end
      # end

      max_bones
    end

    def count_supported_morph_attributes(attributes)
      if @material.morph_targets
        @material.num_supported_morph_normals = count_supported_morph_attribute(attributes, 'morphTarget', @renderer.max_morph_normals)
      end
      if @material.morph_normals
        @material.num_supported_morph_normals = count_supported_morph_attribute(attributes, 'morphNormal', @renderer.max_morph_normals)
      end
    end

    def count_supported_morph_attribute(attributes, base, max)
      max.times.reduce do |num, i|
        attribute = attributes["#{base}#{i}"]
        attribute && attribute >= 0 ? num + 1 : num
      end
    end

    def get_uniforms_list
      @shader[:uniforms].map { |(key, uniform)|
        location = @material.program.uniforms[key]
        if location
          [uniform, location]
        end
      }.compact
    end

    def program_parameters(lights, fog, object)
      # heuristics to create shader paramaters according to lights in the scene
      # (not to blow over max_lights budget)

      max_light_count = allocate_lights(lights)
      max_shadows = allocate_shadows(lights)
      max_bones = allocate_bones(object)

      {
        supports_vertex_textures: @renderer.supports_vertex_textures?,

        map: !!@material.map,
        env_map: !!@material.env_map,
        env_map_mode: @material.env_map && @material.env_map.mapping,
        light_map: !!@material.light_map,
        bump_map: !!@material.light_map,
        normal_map: !!@material.normal_map,
        specular_map: !!@material.specular_map,
        alpha_map: !!@material.alpha_map,

        combine: @material.combine,

        vertex_colors: @material.vertex_colors,

        fog: fog,
        use_fog: @material.fog,
        # fog_exp: fog.is_a?(FogExp2), # TODO: when FogExp2 exists

        flat_shading: @material.shading == FlatShading,

        size_attenuation: @material.size_attenuation,
        logarithmic_depth_buffer: @renderer.logarithmic_depth_buffer,

        skinning: @material.skinning,
        max_bones: max_bones,
        use_vertex_texture: @renderer.supports_bone_textures?,

        morph_targets: @material.morph_targets,
        morph_normals: @material.morph_normals,
        max_morph_targets: @renderer.max_morph_targets,
        max_morph_normals: @renderer.max_morph_normals,

        max_dir_lights: max_light_count[:directional],
        max_point_lights: max_light_count[:point],
        max_spot_lights: max_light_count[:spot],
        max_hemi_lights: max_light_count[:hemi],

        max_shadows: max_shadows,
        shadow_map_enabled: @renderer.shadow_map_enabled? && object.receive_shadow && max_shadows > 0,
        shadow_map_type: @renderer.shadow_map_type,
        shadow_map_debug: @renderer.shadow_map_debug,
        shadow_map_cascade: @renderer.shadow_map_cascade,

        alpha_test: @material.alpha_test,
        metal: @material.metal,
        wrap_around: @material.wrap_around,
        double_sided: @material.side == DoubleSide,
        flip_sided: @material.side == BackSide
      }
    end

    def program_slug(parameters)
      chunks = []

      if shader_id
        chunks << shader_id
      else
        chunks << @material.fragment_shader
        chunks << @material.vertex_shader
      end

      if !@material.defines.nil?
        @material.defines.each do |(name, define)|
          chunks << name
          chunks << define
        end
      end

      parameters.each do |(name, parameter)|
        chunks << name
        chunks << parameter
      end

      chunks.join
    end

    def find_or_create_program(lights, fog, object)
      parameters = program_parameters(lights, fog, object)
      code = program_slug(parameters)

      program = @renderer.programs.find do |program_info|
        program_info.code == code
      end

      if program.nil?
        program = OpenGLProgram.new(@renderer, code, @material, parameters)
        @renderer.programs.push(program)

        @renderer.info[:memory][:programs] = @renderer.programs.length
      else
        program.used_times += 1
      end

      program
    end
  end
end
