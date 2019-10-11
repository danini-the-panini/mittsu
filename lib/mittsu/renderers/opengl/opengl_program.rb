require 'erb'
require 'mittsu/renderers/opengl/opengl_shader'

module Mittsu
  class OpenGLProgram
    attr_reader :id, :program, :uniforms
    attr_accessor :code, :used_times, :attributes, :vertex_shader, :fragment_shader

    def initialize(renderer, code, material, parameters)
      @id = (@@id ||= 1).tap { @@id += 1 }
      @renderer = renderer

      compile_and_link_program(material, parameters)

      cache_uniform_locations(material.shader[:uniforms] || {}, parameters)
      cache_attribute_locations(material.attributes || {}, parameters)

      @code = code
      @used_times = 2
    end

    private

    def compile_and_link_program(material, parameters)
      @program = glCreateProgram

      # TODO: necessary for OpenGL?
      # index0_attribute_name = material.index0_attribute_name
      #
      # if index0_attribute_name.nil? && parameters[:morph_targets]
      #   # programs with morph_targets displace position of attribute 0
      #
      #   index0_attribute_name = 'position'
      # end

      compile_shaders(material, parameters)

      # if !index0_attribute_name.nil?
        # TODO: is this necessary in OpenGL ???
        # Force a particular attribute to index 0.
        # because potentially expensive emulation is done by __browser__ if attribute 0 is disabled. (no browser here!)
        # And, color, for example is often automatically bound to index 0 so disabling it

      #   glBindAttributeLocation(program, 0, index0_attribute_name)
      # end

      glLinkProgram(@program)
      check_for_link_errors
      post_link_clean_up
    end

    def generate_defines(defines)
      chunks = []

      defines.each do |d, value|
        next if value == false

        chunk = "#define #{d} #{value}"
        chunks << chunk
      end

      chunks.join("\n")
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

    def check_for_link_errors
      log_info = program_info_log

      if !link_status
        puts "ERROR: Mittsu::OpenGLProgram: shader error: #{glGetError}, GL_INVALID_STATUS, #{glGetProgramParameter(program, GL_VALIDATE_STATUS)}, glGetProgramParameterInfoLog, #{log_info}"
      end

      if !log_info.empty?
        puts "WARNING: Mittsu::OpenGLProgram: glGetProgramInfoLog, #{log_info}"
        # TODO: useless in OpenGL ???
        # puts "WARNING: #{glGetExtension( 'OPENGL_debug_shaders' ).getTranslatedShaderSource( glVertexShader )}"
        # puts "WARNING: #{glGetExtension( 'OPENGL_debug_shaders' ).getTranslatedShaderSource( glFragmentShader )}"
      end
    end

    def get_shadow_map_define(shadow_map_param)
      case shadow_map_param
      when PCFShadowMap
        'SHADOWMAP_TYPE_PCF'
      when PCFSoftShadowMap
        'SHADOWMAP_TYPE_PCF_SOFT'
      else
        'SHADOWMAP_TYPE_BASIC'
      end
    end

    def get_env_map_type_define(env_map_param, material)
      return 'ENVMAP_TYPE_CUBE' unless env_map_param
      case material.env_map.mapping
      when CubeReflectionMapping, CubeRefractionMapping
        'ENVMAP_TYPE_CUBE'
      when EquirectangularReflectionMapping, EquirectangularRefractionMapping
        'ENVMAP_TYPE_EQUIREC'
      when SphericalReflectionMapping
        'ENVMAP_TYPE_SPHERE'
      else
        'ENVMAP_TYPE_CUBE'
      end
    end

    def get_env_map_mode_define(env_map_param, material)
      return 'ENVMAP_MODE_REFLECTION' unless env_map_param
      case material.env_map.mapping
      when CubeRefractionMapping, EquirectangularRefractionMapping
        'ENVMAP_MODE_REFRACTION'
      else
        'ENVMAP_MODE_REFLECTION'
      end
    end

    def get_env_map_blending_define(env_map_param, material)
      return 'ENVMAP_BLENDING_MULTIPLY' unless env_map_param
      case material.combine
      when MultiplyOperation
        'ENVMAP_BLENDING_MULTIPLY'
      when MixOperation
        'ENVMAP_BLENDING_MIX'
      when AddOperation
        'ENVMAP_BLENDING_ADD'
      else
        'ENVMAP_BLENDING_MULTIPLY'
      end
    end

    def compile_shaders(material, parameters)
      shadow_map_type_define = get_shadow_map_define(parameters[:shadow_map_type])

      env_map_type_define = get_env_map_type_define(parameters[:env_map], material)
      env_map_mode_define = get_env_map_mode_define(parameters[:env_map], material)
      env_map_blending_define = get_env_map_blending_define(parameters[:env_map], material)

      gamma_factor_define = (@renderer.gamma_factor > 0) ? @renderer.gamma_factor : 1.0

      custom_defines = generate_defines(material.defines || {})

      if false # material.is_a?(RawShaderMaterial) # TODO: when RawShaderMaterial exists
        prefix_vertex = ''
        prefix_fragment = ''
      else
        prefix_vertex = File.read(File.expand_path('../../shaders/shader_templates/vertex.glsl.erb', __FILE__))
        prefix_fragment = File.read(File.expand_path('../../shaders/shader_templates/fragment.glsl.erb', __FILE__))
      end

      @vertex_shader = OpenGLShader.new(GL_VERTEX_SHADER, compile_shader_template(prefix_vertex + material.shader[:vertex_shader], binding))
      @fragment_shader = OpenGLShader.new(GL_FRAGMENT_SHADER, compile_shader_template(prefix_fragment + material.shader[:fragment_shader], binding))

      glAttachShader(@program, @vertex_shader.shader)
      glAttachShader(@program, @fragment_shader.shader)
    end

    def compile_shader_template(template, b)
      ERB.new(template).result(b)
    end

    def post_link_clean_up
      glDeleteShader(@vertex_shader.shader)
      glDeleteShader(@fragment_shader.shader)
    end

    def cache_uniform_locations(uniforms, parameters)
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

      @uniforms = {}
      identifiers.each do |id|
        @uniforms[id] = glGetUniformLocation(program, id)
      end
    end

    def cache_attribute_locations(attributes, parameters)
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

      @attributes = {}
      identifiers.each do |id|
        @attributes[id] = glGetAttribLocation(program, id)
      end
    end
  end
end
