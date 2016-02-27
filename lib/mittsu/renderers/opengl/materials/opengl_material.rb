module Mittsu
  class OpenGLMaterial
    attr_reader :shader, :uniforms_list

    def initialize(material, renderer)
      @material = material
      @renderer = renderer
    end

    def init(lights, fog, object)
      # TODO!!!
      # @material.add_event_listener(:dispose, @on_material_dispose)

      # TODO!!!
      shader_id = @renderer.instance_variable_get(:@shader_ids)[@material.class]

      if shader_id
        shader = ShaderLib[shader_id]
        @shader = {
          uniforms: UniformsUtils.clone(shader.uniforms),
          vertex_shader: shader.vertex_shader,
          fragment_shader: shader.fragment_shader
        }
      else
        @shader = {
          uniforms: @material.uniforms,
          vertex_shader: @material.vertex_shader,
          fragment_shader: @material.fragment_shader
        }
      end

      # heuristics to create shader paramaters according to lights in the scene
      # (not to blow over max_lights budget)

      max_light_count = allocate_lights(lights)
      max_shadows = allocate_shadows(lights)
      max_bones = allocate_bones(object)

      parameters = {
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

      # generate code

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

      code = chunks.join

      program = nil

      # check if code has been already compiled

      @renderer.programs.each do |program_info|
        if program_info.code == code
          program = program_info
          program.used_times += 1
          break
        end
      end

      if program.nil?
        program = OpenGLProgram.new(@renderer, code, @material, parameters)
        @renderer.programs.push(program)

        @renderer.info[:memory][:programs] = @renderer.programs.length
      end

      @material.program = program

      attributes = program.attributes

      if @material.morph_targets
        @material.num_supported_morph_targets = 0
        base = 'morphTarget'

        @renderer.max_morph_targets.times do |i|
          id = base + i
          if attributes[id] >= 0
            @material.num_supported_morph_targets += 1
          end
        end
      end

      if @material.morph_normals
        @material.num_supported_morph_normals = 0
        base = 'morphNormal'

        @renderer.max_morph_normals.times do |i|
          id = base + i
          if attributes[id] >= 0
            @material.num_supported_morph_normals += 1
          end
        end
      end

      @uniforms_list = []

      @shader[:uniforms].each_key do |u|
        location = @material.program.uniforms[u]

        if location
          @uniforms_list << [@shader[:uniforms][u], location]
        end
      end
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

    private

    def allocate_lights(lights)
      dir_lights = 0
      point_lights = 0
      spot_lights = 0
      hemi_lights = 0

      lights.each do |light|
        next if light.only_shadow || !light.visible

        dir_lights   += 1 if light.is_a? DirectionalLight
        point_lights += 1 if light.is_a? PointLight
        spot_lights  += 1 if light.is_a? SpotLight
        hemi_lights  += 1 if light.is_a? HemisphereLight
      end

      {
        directional: dir_lights,
        point: point_lights,
        spot: spot_lights,
        hemi: hemi_lights
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
  end
end
