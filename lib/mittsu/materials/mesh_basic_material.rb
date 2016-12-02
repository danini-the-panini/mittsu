require 'mittsu/math'
require 'mittsu/materials/material'

# parameters = {
#  color: <hex>,
#  opacity: <float>,
#  map: Mittsu::Texture.new( <Image> ),
#
#  light_map: Mittsu::Texture.new( <Image> ),
#
#  specular_map: Mittsu::Texture.new( <Image> ),
#
#  alpha_map: Mittsu::Texture.new( <Image> ),
#
#  env_map: Mittsu::TextureCube.new( [posx, negx, posy, negy, posz, negz] ),
#  combine: Mittsu::Multiply,
#  reflectivity: <float>,
#  refraction_ratio: <float>,
#
#  shading: Mittsu::SmoothShading,
#  blending: Mittsu::NormalBlending,
#  depth_test: <bool>,
#  depth_write: <bool>,
#
#  wireframe: <boolean>,
#  wireframe_linewidth: <float>,
#
#  vertex_colors: Mittsu::NoColors / Mittsu::VertexColors / Mittsu::FaceColors,
#
#  skinning: <bool>,
#  morph_targets: <bool>,
#
#  fog: <bool>
# }
module Mittsu
  class MeshBasicMaterial < Material

    attr_accessor :color, :map, :light_map, :specular_map, :alpha_map, :env_map, :combine, :reflectivity, :refraction_ratio, :shading, :wireframe, :wireframe_linewidth, :wireframe_linecap, :wireframe_linejoin, :vertex_colors, :skinning, :morph_targets, :fog

    def initialize(parameters = {})
      super()

      @type = 'MeshBasicMaterial'

      @color = Color.new(0xffffff) # emissive

      @map = nil

      @light_map = nil

      @specular_map = nil

      @alpha_map = nil

      @env_map = nil
      @combine = MultiplyOperation
      @reflectivity = 1.0
      @refraction_ratio = 0.98

      @fog = true

      @shading = SmoothShading

      @wireframe = false
      @wireframe_linewidth = 1
      @wireframe_linecap = :round
      @wireframe_linejoin = :round

      @vertex_colors = NoColors

      @skinning = false
      @morph_targets = false

      set_values(parameters)
    end

    def clone
      material = Material.new

      super(material)

      material.color.copy(@color)

      material.map = @map

      material.lightMap = @lightMap

      material.specularMap = @specularMap

      material.alphaMap = @alphaMap

      material.envMap = @envMap
      material.combine = @combine
      material.reflectivity = @reflectivity
      material.refractionRatio = @refractionRatio

      material.fog = @fog

      material.shading = @shading

      material.wireframe = @wireframe
      material.wireframeLinewidth = @wireframeLinewidth
      material.wireframeLinecap = @wireframeLinecap
      material.wireframeLinejoin = @wireframeLinejoin

      material.vertexColors = @vertexColors

      material.skinning = @skinning
      material.morphTargets = @morphTargets

      material
    end
  end
end
