require 'mittsu/renderers/shaders/uniforms_utils'
require 'mittsu/renderers/shaders/uniforms_lib'
require 'mittsu/renderers/shaders/shader_chunk'
require 'mittsu/renderers/shaders/rbsl_loader'

module Mittsu
  class ShaderLib_Instance
    attr_accessor :uniforms, :vertex_shader, :fragment_shader
    def initialize(options = {})
      @uniforms = options.fetch(:uniforms)
      @vertex_shader = options.fetch(:vertex_shader)
      @fragment_shader = options.fetch(:fragment_shader)
    end
  end
  private_constant :ShaderLib_Instance

  SHADER_LIB_HASH = {
    basic: ShaderLib_Instance.new(
      uniforms: UniformsUtils.merge([
        UniformsLib[:common],
        UniformsLib[:fog],
        UniformsLib[:shadowmap]
      ]),

      vertex_shader: [
        ShaderChunk[:common],
        ShaderChunk[:map_pars_vertex],
        ShaderChunk[:lightmap_pars_vertex],
        ShaderChunk[:envmap_pars_vertex],
        ShaderChunk[:color_pars_vertex],
        ShaderChunk[:morphtarget_pars_vertex],
        ShaderChunk[:skinning_pars_vertex],
        ShaderChunk[:shadowmap_pars_vertex],
        ShaderChunk[:logdepthbuf_pars_vertex],

        "void main() {",

          ShaderChunk[:map_vertex],
          ShaderChunk[:lightmap_vertex],
          ShaderChunk[:color_vertex],
          ShaderChunk[:skinbase_vertex],

        "  #ifdef USE_ENVMAP",

          ShaderChunk[:morphnormal_vertex],
          ShaderChunk[:skinnormal_vertex],
          ShaderChunk[:defaultnormal_vertex],

        "  #endif",

          ShaderChunk[:morphtarget_vertex],
          ShaderChunk[:skinning_vertex],
          ShaderChunk[:default_vertex],
          ShaderChunk[:logdepthbuf_vertex],

          ShaderChunk[:worldpos_vertex],
          ShaderChunk[:envmap_vertex],
          ShaderChunk[:shadowmap_vertex],

        "}"

      ].join("\n"),

      fragment_shader: [

        "uniform vec3 diffuse;",
        "uniform float opacity;",

        ShaderChunk[:common],
        ShaderChunk[:color_pars_fragment],
        ShaderChunk[:map_pars_fragment],
        ShaderChunk[:alphamap_pars_fragment],
        ShaderChunk[:lightmap_pars_fragment],
        ShaderChunk[:envmap_pars_fragment],
        ShaderChunk[:fog_pars_fragment],
        ShaderChunk[:shadowmap_pars_fragment],
        ShaderChunk[:specularmap_pars_fragment],
        ShaderChunk[:logdepthbuf_pars_fragment],

        "void main() {",

        "  vec3 outgoingLight = vec3( 0.0 );",  # outgoing light does not have an alpha, the surface does
        "  vec4 diffuseColor = vec4( diffuse, opacity );",

          ShaderChunk[:logdepthbuf_fragment],
          ShaderChunk[:map_fragment],
          ShaderChunk[:color_fragment],
          ShaderChunk[:alphamap_fragment],
          ShaderChunk[:alphatest_fragment],
          ShaderChunk[:specularmap_fragment],

        "  outgoingLight = diffuseColor.rgb;", # simple shader

          ShaderChunk[:lightmap_fragment],    # TODO: Light map on an otherwise unlit surface doesn't make sense.
          ShaderChunk[:envmap_fragment],
          ShaderChunk[:shadowmap_fragment],    # TODO: Shadows on an otherwise unlit surface doesn't make sense.

          ShaderChunk[:linear_to_gamma_fragment],

          ShaderChunk[:fog_fragment],

        "  fragColor = vec4( outgoingLight, diffuseColor.a );",  # TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

        "}"

      ].join("\n")
    ),
    lambert: ShaderLib_Instance.new(
      uniforms: UniformsUtils.merge([
        UniformsLib[:common],
        UniformsLib[:fog],
        UniformsLib[:lights],
        UniformsLib[:shadow_map],
        {
          'emissive' => Uniform.new(:c, Color.new(0x000000)),
          'wrapRGB' => Uniform.new(:v3, Vector3.new(1.0, 1.0, 1.0))
        }
      ]),
      vertex_shader: [
        '#define LAMBERT',
        'out vec3 vLightFront;',
        '#ifdef DOUBLE_SIDED',
        '  out vec3 vLightBack;',
        '#endif',
        ShaderChunk[:common],
        ShaderChunk[:map_pars_vertex],
        ShaderChunk[:lightmap_pars_vertex],
        ShaderChunk[:envmap_pars_vertex],
        ShaderChunk[:lights_lambert_pars_vertex],
        ShaderChunk[:color_pars_vertex],
        ShaderChunk[:morphtarget_pars_vertex],
        ShaderChunk[:skinning_pars_vertex],
        ShaderChunk[:shadowmap_pars_vertex],
        ShaderChunk[:logdepthbuf_pars_vertex],
        'void main() {',

          ShaderChunk[:map_vertex],
          ShaderChunk[:lightmap_vertex],
          ShaderChunk[:color_vertex],

          ShaderChunk[:morphnormal_vertex],
          ShaderChunk[:skinbase_vertex],
          ShaderChunk[:skinnormal_vertex],
          ShaderChunk[:defaultnormal_vertex],

          ShaderChunk[:morphtarget_vertex],
          ShaderChunk[:skinning_vertex],
          ShaderChunk[:default_vertex],
          ShaderChunk[:logdepthbuf_vertex],

          ShaderChunk[:worldpos_vertex],
          ShaderChunk[:envmap_vertex],
          ShaderChunk[:lights_lambert_vertex],
          ShaderChunk[:shadowmap_vertex],

        '}',
      ].join("\n"),
      fragment_shader: [
        'uniform vec3 diffuse;',
        'uniform vec3 emissive;',
        'uniform float opacity;',

        'in vec3 vLightFront;',

        '#ifdef DOUBLE_SIDED',
        '  in vec3 vLightBack;',
        '#endif',

        ShaderChunk[:common],
        ShaderChunk[:color_pars_fragment],
        ShaderChunk[:map_pars_fragment],
        ShaderChunk[:alphamap_pars_fragment],
        ShaderChunk[:lightmap_pars_fragment],
        ShaderChunk[:envmap_pars_fragment],
        ShaderChunk[:fog_pars_fragment],
        ShaderChunk[:shadowmap_pars_fragment],
        ShaderChunk[:specularmap_pars_fragment],
        ShaderChunk[:logdepthbuf_pars_fragment],

        'void main() {',

        '  vec3 outgoingLight = vec3( 0.0 );',  # outgoing light does not have an alpha, the surface does
        '  vec4 diffuseColor = vec4( diffuse, opacity );',

          ShaderChunk[:logdepthbuf_fragment],
          ShaderChunk[:map_fragment],
          ShaderChunk[:color_fragment],
          ShaderChunk[:alphamap_fragment],
          ShaderChunk[:alphatest_fragment],
          ShaderChunk[:specularmap_fragment],

        '  #ifdef DOUBLE_SIDED',

            #'float isFront = float( gl_FrontFacing );',
            #'fragColor.xyz *= isFront * vLightFront + ( 1.0 - isFront ) * vLightBack;',

        '    if ( gl_FrontFacing )',
        '      outgoingLight += diffuseColor.rgb * vLightFront + emissive;',
        '    else',
        '      outgoingLight += diffuseColor.rgb * vLightBack + emissive;',

        '  #else',

        '    outgoingLight += diffuseColor.rgb * vLightFront + emissive;',

        '  #endif',

          ShaderChunk[:lightmap_fragment],
          ShaderChunk[:envmap_fragment],
          ShaderChunk[:shadowmap_fragment],

          ShaderChunk[:linear_to_gamma_fragment],

          ShaderChunk[:fog_fragment],

        # '  fragColor = vec4( outgoingLight, diffuseColor.a );',  # TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

        '  fragColor = vec4(outgoingLight, diffuseColor.a);',
        '}'
      ].join("\n")
    ),
    phong: ShaderLib_Instance.new(
      uniforms: UniformsUtils.merge([
        UniformsLib[:common],
        UniformsLib[:bump],
        UniformsLib[:normal_map],
        UniformsLib[:fog],
        UniformsLib[:lights],
        UniformsLib[:shadow_map],
        {
          'emissive'  => Uniform.new(:c, Color.new(0x000000)),
          'specular'  => Uniform.new(:c, Color.new(0x111111)),
          'shininess' => Uniform.new(:f, 30.0),
          'wrapRGB'   => Uniform.new(:v3, Vector3.new(1.0, 1.0, 1.0))
        }
      ]),
      vertex_shader: [
        '#define PHONG',
        'out vec3 vViewPosition;',
        '#ifndef FLAT_SHADED',
        '  out vec3 vNormal;',
        '#endif',

        ShaderChunk[:common],
        ShaderChunk[:map_pars_vertex],
        ShaderChunk[:lightmap_pars_vertex],
        ShaderChunk[:envmap_pars_vertex],
        ShaderChunk[:lights_phong_pars_vertex],
        ShaderChunk[:color_pars_vertex],
        ShaderChunk[:morphtarget_pars_vertex],
        ShaderChunk[:skinning_pars_vertex],
        ShaderChunk[:shadowmap_pars_vertex],
        ShaderChunk[:logdepthbuf_pars_vertex],

        'void main() {',

          ShaderChunk[:map_vertex],
          ShaderChunk[:lightmap_vertex],
          ShaderChunk[:color_vertex],

          ShaderChunk[:morphnormal_vertex],
          ShaderChunk[:skinbase_vertex],
          ShaderChunk[:skinnormal_vertex],
          ShaderChunk[:defaultnormal_vertex],

        '#ifndef FLAT_SHADED', # Normal computed with derivatives when FLAT_SHADED
        '  vNormal = normalize( transformedNormal );',
        '#endif',

          ShaderChunk[:morphtarget_vertex],
          ShaderChunk[:skinning_vertex],
          ShaderChunk[:default_vertex],
          ShaderChunk[:logdepthbuf_vertex],

        '  vViewPosition = -mvPosition.xyz;',

          ShaderChunk[:worldpos_vertex],
          ShaderChunk[:envmap_vertex],
          ShaderChunk[:lights_phong_vertex],
          ShaderChunk[:shadowmap_vertex],
        '}'
      ].join("\n"),
      fragment_shader: [
        '#define PHONG',

        'uniform vec3 diffuse;',
        'uniform vec3 emissive;',
        'uniform vec3 specular;',
        'uniform float shininess;',
        'uniform float opacity;',

        ShaderChunk[:common],
        ShaderChunk[:color_pars_fragment],
        ShaderChunk[:map_pars_fragment],
        ShaderChunk[:alphamap_pars_fragment],
        ShaderChunk[:lightmap_pars_fragment],
        ShaderChunk[:envmap_pars_fragment],
        ShaderChunk[:fog_pars_fragment],
        ShaderChunk[:lights_phong_pars_fragment],
        ShaderChunk[:shadowmap_pars_fragment],
        ShaderChunk[:bumpmap_pars_fragment],
        ShaderChunk[:normalmap_pars_fragment],
        ShaderChunk[:specularmap_pars_fragment],
        ShaderChunk[:logdepthbuf_pars_fragment],

        'void main() {',

        '  vec3 outgoingLight = vec3( 0.0 );',  # outgoing light does not have an alpha, the surface does
        '  vec4 diffuseColor = vec4( diffuse, opacity );',

          ShaderChunk[:logdepthbuf_fragment],
          ShaderChunk[:map_fragment],
          ShaderChunk[:color_fragment],
          ShaderChunk[:alphamap_fragment],
          ShaderChunk[:alphatest_fragment],
          ShaderChunk[:specularmap_fragment],

          ShaderChunk[:lights_phong_fragment],

          ShaderChunk[:lightmap_fragment],
          ShaderChunk[:envmap_fragment],
          ShaderChunk[:shadowmap_fragment],

          ShaderChunk[:linear_to_gamma_fragment],

          ShaderChunk[:fog_fragment],

        '  fragColor = vec4( outgoingLight, diffuseColor.a );',  # TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

        '}'
      ].join("\n")
    ),
    # TODO:
    # particle_basic
    # dashed
    # depth
    # normal
    cube: ShaderLib_Instance.new(
      uniforms: {
        'tCube' => Uniform.new(:t, nil),
        'tFlip' => Uniform.new(:f, -1.0)
      },
      vertex_shader: [
        'out vec3 vWorldPosition;',

        ShaderChunk[:common],
        ShaderChunk[:logdepthbuf_pars_vertex],

        'void main() {',
        '  vWorldPosition = transformDirection( position, modelMatrix );',
        '  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
          ShaderChunk[:logdepthbuf_vertex],
        '}'
      ].join("\n"),
      fragment_shader: [
        'uniform samplerCube tCube;',
        'uniform float tFlip;',

        'in vec3 vWorldPosition;',

        ShaderChunk[:common],
        ShaderChunk[:logdepthbuf_pars_fragment],

        'void main() {',
        '  fragColor = texture( tCube, vec3( tFlip * vWorldPosition.x, vWorldPosition.yz ) );',
          ShaderChunk[:logdepthbuf_fragment],
        '}'
      ].join("\n")
    ),
    # equirect
    depth_rgba: ShaderLib_Instance.new(
      uniforms: {},
      vertex_shader: [
        ShaderChunk[:common],
        ShaderChunk[:morphtarget_pars_vertex],
        ShaderChunk[:skinning_pars_vertex],
        ShaderChunk[:logdepthbuf_pars_vertex],

        'void main() {',
          ShaderChunk[:skinbase_vertex],
          ShaderChunk[:morphtarget_vertex],
          ShaderChunk[:skinning_vertex],
          ShaderChunk[:default_vertex],
          ShaderChunk[:logdepthbuf_vertex],
        '}'
      ].join("\n"),
      fragment_shader: [
        ShaderChunk[:common],
        ShaderChunk[:logdepthbuf_pars_fragment],

        'vec4 pack_depth( const in float depth ) {',

        '  const vec4 bit_shift = vec4( 256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0 );',
        '  const vec4 bit_mask = vec4( 0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0 );',
        '  vec4 res = mod( depth * bit_shift * vec4( 255 ), vec4( 256 ) ) / vec4( 255 );', # '  vec4 res = fract( depth * bit_shift );',
        '  res -= res.xxyz * bit_mask;',
        '  return res;',

        '}',

        'void main() {',
          ShaderChunk[:logdepthbuf_fragment],

        '  #ifdef USE_LOGDEPTHBUF_EXT',

        '    fragColor   = pack_depth( gl_FragDepthEXT );',

        '  #else',

        '    fragColor = pack_depth( gl_FragCoord.z );',

        '  #endif',

          #'fragColor = pack_depth( gl_FragCoord.z / gl_FragCoord.w );',
          #'float z = ( ( gl_FragCoord.z / gl_FragCoord.w ) - 3.0 ) / ( 4000.0 - 3.0 );',
          #'fragColor = pack_depth( z );',
          #'fragColor = vec4( z, z, z, 1.0 );',
        '}'
      ].join("\n")
    )
  }

  class ShaderLib
    def self.create_shader(id, options={})
      shader = self[id]
      {
        uniforms: UniformsUtils.clone(shader.uniforms),
        vertex_shader: shader.vertex_shader,
        fragment_shader: shader.fragment_shader
      }.merge(options)
    end

    def self.[](id)
      SHADER_LIB_HASH[id]
    end
  end
end
