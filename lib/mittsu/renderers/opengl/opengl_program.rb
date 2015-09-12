require 'mittsu/renderers/opengl/opengl_shader'

module Mittsu
  class OpenGLProgram
    attr_reader :id, :program, :uniforms, :attributes
    attr_accessor :code, :used_times, :attributes, :vertex_shader, :fragment_shader

    def initialize(renderer, code, material, parameters)
      defines = material.defines || {} # TODO: setting to default object... ?
      uniforms = material[:_opengl_shader][:uniforms]
      attributes = material.attributes || [] # TODO: setting to default array... ?

      vertex_shader = material[:_opengl_shader][:vertex_shader]
      fragment_shader = material[:_opengl_shader][:fragment_shader]

      # TODO: necessary for OpenGL?
      # index0_attribute_name = material.index0_attribute_name
      #
      # if index0_attribute_name.nil? && parameters[:morph_targets]
      #   # programs with morph_targets displace position of attribute 0
      #
      #   index0_attribute_name = 'position'
      # end

      shadow_map_type_define = 'SHADOWMAP_TYPE_BASIC'

      if parameters[:shadow_map_type] == PCFShadowMap
        shadow_map_type_define = 'SHADOWMAP_TYPE_PCF_SOFT'
      elsif parameters[:shadow_map_type] == PCFSoftShadowMap
        shadow_map_type_define = 'SHADOWMAP_TYPE_PCF_SOFT'
      end

      env_map_type_define = 'ENVMAP_TYPE_CUBE'
      env_map_mode_define = 'ENVMAP_MODE_REFLECTION'
      env_map_blending_define = 'ENVMAP_BLENDING_MULTIPLY'

      if parameters[:env_map]
        case material.env_map.mapping
        when CubeReflectionMapping, CubeRefractionMapping
          env_map_type_define = 'ENVMAP_TYPE_CUBE'
        when EquirectangularReflectionMapping, EquirectangularRefractionMapping
          env_map_type_define = 'ENVMAP_TYPE_EQUIREC'
        when SphericalReflectionMapping
          env_map_type_define = 'ENVMAP_TYPE_SPHERE'
        end

        case material.env_map.mapping
        when CubeRefractionMapping, EquirectangularRefractionMapping
          env_map_mode_define 'ENVMAP_MODE_REFRACTION'
        end

        case material.combine
        when MultiplyOperation
          env_map_blending_define = 'ENVMAP_BLENDING_MULTIPLY'
        when MixOperation
          env_map_blending_define = 'ENVMAP_BLENDING_MIX'
        when AddOperation
          env_map_blending_define = 'ENVMAP_BLENDING_ADD'
        end
      end

      gamma_factor_define = (renderer.gamma_factor > 0) ? renderer.gamma_factor : 1.0

      # puts 'building new program'

      #

      custom_defines = generate_defines(defines)

      #

      @program = glCreateProgram

      if false # material.is_a?(RawShaderMaterial) # TODO: when RawShaderMaterial exists
        prefix_vertex = ''
        prefix_fragment = ''
      else
        prefix_vertex = [
          '#version 330',
          # TODO: do we need precision for an OpenGL program?
          # "precision #{parameters[:precision]} float;",
          # "precision #{parameters[:precision]} int;",

          custom_defines,

          parameters[:supports_vertex_textures] ? '#define VERTEX_TEXTURES' : '',

          renderer.gamma_input ? '#define GAMMA_INPUT' : '',
          renderer.gamma_output ? '#define GAMMA_OUTPUT' : '',
          "#define GAMMA_FACTOR #{gamma_factor_define}",

          "#define MAX_DIR_LIGHTS #{parameters[:max_dir_lights]}",
          "#define MAX_POINT_LIGHTS #{parameters[:max_point_lights]}",
          "#define MAX_SPOT_LIGHTS #{parameters[:max_spot_lights]}",
          "#define MAX_HEMI_LIGHTS #{parameters[:max_hemi_lights]}",

          "#define MAX_SHADOWS #{parameters[:max_shadows]}",

          "#define MAX_BONES #{parameters[:max_bones]}",

          parameters[:map] ? '#define USE_MAP' : '',
          parameters[:env_map] ? '#define USE_ENVMAP' : '',
          parameters[:env_map] ? "#define #{env_map_mode_define}" : '',
          parameters[:light_map] ? '#define USE_LIGHTMAP' : '',
          parameters[:bump_map] ? '#define USE_BUMPMAP' : '',
          parameters[:normal_map] ? '#define USE_NORMALMAP' : '',
          parameters[:specular_map] ? '#define USE_SPECULARMAP' : '',
          parameters[:alpha_map] ? '#define USE_ALPHAMAP' : '',
          parameters[:vertex_colors] ? '#define USE_COLOR' : '',

          parameters[:flat_shading] ? '#define FLAT_SHADED': '',

          parameters[:skinning] ? '#define USE_SKINNING' : '',
          parameters[:use_vertex_texture] ? '#define BONE_TEXTURE' : '',

          parameters[:morph_targets] ? '#define USE_MORPHTARGETS' : '',
          parameters[:morph_normals] ? '#define USE_MORPHNORMALS' : '',
          parameters[:wrap_around] ? '#define WRAP_AROUND' : '',
          parameters[:double_sided] ? '#define DOUBLE_SIDED' : '',
          parameters[:flip_sided] ? '#define FLIP_SIDED' : '',

          parameters[:shadow_map_enabled] ? '#define USE_SHADOWMAP' : '',
          parameters[:shadow_map_enabled] ? "#define #{shadow_map_type_define}" : '',
          parameters[:shadow_map_debug] ? '#define SHADOWMAP_DEBUG' : '',
          parameters[:shadow_map_cascade] ? '#define SHADOWMAP_CASCADE' : '',

          parameters[:size_attenuation] ? '#define USE_SIZEATTENUATION' : '',

          parameters[:logarithmic_depth_buffer] ? '#define USE_LOGDEPTHBUF' : '',
          #renderer._glExtensionFragDepth ? '#define USE_LOGDEPTHBUF_EXT' : '',


          'uniform mat4 modelMatrix;',
          'uniform mat4 modelViewMatrix;',
          'uniform mat4 projectionMatrix;',
          'uniform mat4 viewMatrix;',
          'uniform mat3 normalMatrix;',
          'uniform vec3 cameraPosition;',

          'in vec3 position;',
          'in vec3 normal;',
          'in vec2 uv;',
          'in vec2 uv2;',

          '#ifdef USE_COLOR',

          '  in vec3 color;',

          '#endif',

          '#ifdef USE_MORPHTARGETS',

          '  in vec3 morphTarget0;',
          '  in vec3 morphTarget1;',
          '  in vec3 morphTarget2;',
          '  in vec3 morphTarget3;',

          '  #ifdef USE_MORPHNORMALS',

          '    in vec3 morphNormal0;',
          '    in vec3 morphNormal1;',
          '    in vec3 morphNormal2;',
          '    in vec3 morphNormal3;',

          '  #else',

          '    in vec3 morphTarget4;',
          '    in vec3 morphTarget5;',
          '    in vec3 morphTarget6;',
          '    in vec3 morphTarget7;',

          '  #endif',

          '#endif',

          '#ifdef USE_SKINNING',

          '  in vec4 skinIndex;',
          '  in vec4 skinWeight;',

          '#endif',
        ].reject(&:empty?).join("\n") + "\n"

        prefix_fragment = [
          '#version 330',
          # TODO: do we need precision for an OpenGL program?
          # "precison #{parameters[:precision]} float;",
          # "precison #{parameters[:precision]} int;",

          # (parameters[:bump_map] || parameters[:normal_map] || parameters[:flat_shading]) ? '#extension GL_OES_standard_derivatives : enable' : '', # TODO: oes extension in OpenGL?

          custom_defines,

          "#define MAX_DIR_LIGHTS #{parameters[:max_dir_lights]}",
          "#define MAX_POINT_LIGHTS #{parameters[:max_point_lights]}",
          "#define MAX_SPOT_LIGHTS #{parameters[:max_spot_lights]}",
          "#define MAX_HEMI_LIGHTS #{parameters[:max_hemi_lights]}",

          "#define MAX_SHADOWS #{parameters[:max_shadows]}",

          parameters[:alpha_test] ? "#define ALPHATEST #{parameters[:alpha_test].to_f}" : '',

          renderer.gamma_input ? '#define GAMMA_INPUT' : '',
          renderer.gamma_output ? '#define GAMMA_OUTPUT' : '',
          "#define GAMMA_FACTOR #{gamma_factor_define}",

          (parameters[:use_fog] && parameters[:fog]) ? '#define USE_FOG' : '',
          (parameters[:use_fog] && parameters[:fog_exp]) ? '#define FOG_EXP2' : '',

          parameters[:map] ? '#define USE_MAP' : '',
          parameters[:env_map] ? '#define USE_ENVMAP' : '',
          parameters[:env_map] ? "#define #{env_map_type_define}" : '',
          parameters[:env_map] ? "#define #{env_map_mode_define}" : '',
          parameters[:env_map] ? "#define #{env_map_blending_define}" : '',
          parameters[:light_map] ? '#define USE_LIGHTMAP' : '',
          parameters[:bump_map] ? '#define USE_BUMPMAP' : '',
          parameters[:normal_map] ? '#define USE_NORMALMAP' : '',
          parameters[:specular_map] ? '#define USE_SPECULARMAP' : '',
          parameters[:alpha_map] ? '#define USE_ALPHAMAP' : '',
          parameters[:vertex_colors] ? '#define USE_COLOR' : '',

          parameters[:flat_shading] ? '#define FLAT_SHADED' : '',

          parameters[:metal] ? '#define METAL' : '',
          parameters[:wrap_around] ? '#define WRAP_AROUND' : '',
          parameters[:double_sided] ? '#define DOUBLE_SIDED' : '',
          parameters[:flip_sided] ? '#define FLIP_SIDED' : '',


          parameters[:shadow_map_enabled] ? '#define USE_SHADOWMAP' : '',
          parameters[:shadow_map_enabled] ? "#define #{shadow_map_define}" : '',
          parameters[:shadow_map_debug] ? '#define SHADOWMAP_DEBUG' : '',
          parameters[:'shadow_map_cascade'] ? '#define SHADOWMAP_CASCADE' : '',

          parameters[:logarithmic_depth_buffer] ? '#define USE_LOGDEPTHBUF' : '',
          #renderer._glExtensionFragDepth ? '#define USE_LOGDEPTHBUF_EXT' : '',

          'uniform mat4 viewMatrix;',
          'uniform vec3 cameraPosition;',

          "out vec4 fragColor;"
        ].reject(&:empty?).join("\n") + "\n"
      end

      gl_vertex_shader = OpenGLShader.new(GL_VERTEX_SHADER, prefix_vertex + vertex_shader)
      gl_fragment_shader = OpenGLShader.new(GL_FRAGMENT_SHADER, prefix_fragment + fragment_shader)

      glAttachShader(@program, gl_vertex_shader.shader)
      glAttachShader(@program, gl_fragment_shader.shader)

      # if !index0_attribute_name.nil?
        # TODO: is this necessary in OpenGL ???
        # Force a particular attribute to index 0.
        # because potentially expensive emulation is done by __browser__ if attribute 0 is disabled. (no browser here!)
        # And, color, for example is often automatically bound to index 0 so disabling it

      #   glBindAttributeLocation(program, 0, index0_attribute_name)
      # end

      glLinkProgram(@program)

      log_info = program_info_log

      if !link_status
        puts "ERROR: Mittsu::OpenGLProgram: shader error: #{glGetError}, GL_INVALID_STATUS, #{glGetProgramParameter(program, GL_VALIDATE_STATUS)}, glGetProgramParameterInfoLog, #{program_log_info}"
      end

      if !log_info.empty?
        puts "WARNING: Mittsu::OpenGLProgram: glGetProgramInfoLog, #{log_info}"
        # TODO: useless in OpenGL ???
        # puts "WARNING: #{glGetExtension( 'OPENGL_debug_shaders' ).getTranslatedShaderSource( glVertexShader )}"
        # puts "WARNING: #{glGetExtension( 'OPENGL_debug_shaders' ).getTranslatedShaderSource( glFragmentShader )}"
      end

      # clean up

      glDeleteShader(gl_vertex_shader.shader)
      glDeleteShader(gl_fragment_shader.shader)

      # cache uniform locations

      identifiers = [
        'viewMatrix',
        'modelViewMatrix',
        'projectionMatrix',
        'normalMatrix',
        'modelMatrix',
        'cameraPosition',
        'morphTargetInfluences',
        'bindMatrix',
        'bindMatrixInverse'
      ]

      if parameters[:use_vertex_texture]
        identifiers << 'boneTexture'
        identifiers << 'boneTextureWidth'
        identifiers << 'boneTextureHeight'
      else
        identifiers << 'boneGlobalMatrices'
      end

      if parameters[:logarithmic_depth_buffer]
        identifiers << 'logDepthBufFC'
      end

      uniforms.each do |k, v|
        identifiers << k.to_s
      end

      @uniforms = cache_uniform_locations(program, identifiers)

      # cache attributes locations

      identifiers = [
        'position',
        'normal',
        'uv',
        'uv2',
        'tangent',
        'color',
        'skinIndex',
        'skinWeight',
        'lineDistance'
      ]

      parameters[:max_morph_targets].times do |i|
        identifiers << "morphTarget#{i}"
      end

      parameters[:max_morph_normals].times do |i|
        identifiers << "morphNormal#{i}"
      end

      attributes.each do |k, v|
        identifiers << k
      end

      @attributes = cache_attribute_locations(program, identifiers)

      @id = (@@id ||= 1).tap { @@id += 1 }
      @code = code
      @used_times = 2
      @vertex_shader = gl_vertex_shader
      @fragment_shader = gl_fragment_shader
    end

    private

    def generate_defines(defines)
      chunks = []

      defines.each do |d, value|
        next if value == false

        chunk = "#define #{d} #{value}"
        chunks << chunk
      end

      chunks.join("\n")
    end

    def cache_uniform_locations(program, identifiers)
      uniforms = {}

      identifiers.each do |id|
        uniforms[id] = glGetUniformLocation(program, id)
      end

      uniforms
    end

    def cache_attribute_locations(program, identifiers)
      attributes = {}

      identifiers.each do |id|
        attributes[id] = glGetAttribLocation(program, id)
      end

      attributes
    end

    def link_status
      ptr = ' '*8
      glGetProgramiv @program, GL_LINK_STATUS, ptr
      ptr.unpack('L')[0]
    end

    def program_info_log
      ptr = ' '*8
      glGetProgramiv @program, GL_INFO_LOG_LENGTH, ptr
      length = ptr.unpack('L')[0]

      if length > 0
        log = ' '*length
        glGetProgramInfoLog @program, length, ptr, log
        log.unpack("A#{length}")[0]
      else
        ''
      end
    end
  end
end
