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

        "out vec4 fragColor;",

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

    # TODO:
    # lambert
    # phong
    # particle_basic
    # dashed
    # depth
    # normal
    # cube
    # equirect
    # depth_rgba
    )
  }
end
