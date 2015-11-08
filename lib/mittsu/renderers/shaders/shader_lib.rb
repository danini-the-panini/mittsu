require 'mittsu/renderers/shaders/uniforms_utils'
require 'mittsu/renderers/shaders/uniforms_lib'
require 'mittsu/renderers/shaders/shader_chunk'

module Mittsu
  class ShaderLib_Instance
    attr_accessor :uniforms, :vertex_shader, :fragment_shader
    def initialize(uniforms:, vertex_shader:, fragment_shader:)
      @uniforms = uniforms
      @vertex_shader = vertex_shader
      @fragment_shader = fragment_shader
    end
  end

  ShaderLib = {
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
          ShaderChunk[:skin_vertex],
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
        UniformsLib[:shadowmap],
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
        "uniform vec3 diffuse;",
        "uniform vec3 emissive;",
        "uniform float opacity;",

        "in vec3 vLightFront;",

        "#ifdef DOUBLE_SIDED",

        "  in vec3 vLightBack;",

        "#endif",

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

        "  #ifdef DOUBLE_SIDED",

            #"float isFront = float( gl_FrontFacing );",
            #"fragColor.xyz *= isFront * vLightFront + ( 1.0 - isFront ) * vLightBack;",

        "    if ( gl_FrontFacing )",
        "      outgoingLight += diffuseColor.rgb * vLightFront + emissive;",
        "    else",
        "      outgoingLight += diffuseColor.rgb * vLightBack + emissive;",

        "  #else",

        "    outgoingLight += diffuseColor.rgb * vLightFront + emissive;",

        "  #endif",

          ShaderChunk[:lightmap_fragment],
          ShaderChunk[:envmap_fragment],
          ShaderChunk[:shadowmap_fragment],

          ShaderChunk[:linear_to_gamma_fragment],

          ShaderChunk[:fog_fragment],

        # "  fragColor = vec4( outgoingLight, diffuseColor.a );",  # TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects


        "  fragColor = vec4(outgoingLight, diffuseColor.a);",

        "}"

      ].join("\n")
    ),
    # TODO:
    # phong
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
  			'	vWorldPosition = transformDirection( position, modelMatrix );',
  			'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
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
  			'	fragColor = texture( tCube, vec3( tFlip * vWorldPosition.x, vWorldPosition.yz ) );',
  				ShaderChunk[:logdepthbuf_fragment],
  			'}'
      ].join("\n")
    )
    # equirect
    # depth_rgba
  }
end
