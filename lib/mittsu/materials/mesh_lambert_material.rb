require 'mittsu/materials/material'

module Mittsu
  # parameters: {
  #   color: <hex>,
  #   emissive: <hex>,
  #   opacity: <float>,
  #
  #   map: Texture.new( <Image> ),
  #
  #   light_map: Texture.( <Image> ),
  #
  #   specular_map: Texture.new( <Image> ),
  #
  #   alpha_map: Texture.new( <Image> ),
  #
  #   env_map: TextureCube.new( [posx, negx, posy, negy, posz, negz]),
  #   combine: Multiply,
  #   reflectivity: <float>,
  #   refraction_ratio: <float>,
  #
  #   shading: SmoothShading,
  #   blending: NormalBlending,
  #   depth_test: <bool>,
  #   depth_write: <bool>,
  #
  #   wireframe: <boolean>,
  #   wireframe_linewidth: <float>,
  #
  #   vertex_colors: NoColors / VertexColors / FaceColors,
  #
  #   skinning: <bool>,
  #   morph_targets: <bool>,
  #   morph_normals: <bool>,
  #
  #   fog: <bool>
  # }

  attr_accessor :emissive, :shading, :wireframe_linewidth, :wireframe_linecap, :wireframe_linejoin

  class MeshLambertMaterial < Material
    def initialize(parameters = {})
      super()

      @type = 'MeshLambertMaterial'

      @color = Color.new(0xffffff) # diffuse
      @emissive = Color.new(0x000000)

      @wrap_around = false
      @wrap_rbg = Vector3.new(1.0, 1.0, 1.0)

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
      @wireframe_linewidth = 1.0
      @wireframe_linecap = :round
      @wireframe_linejoin = :round

      @vertex_colors = NoColors

      @skinning = false
      @morph_targets = false
      @morph_normals = false

      self.set_values(parameters)
    end

    def clone
      material = MeshLambertMaterial.new

      super(material)

      material.color.copy(@color)
      material.emissive.copy(@color)

      material.wrap_around = @wrap_around
      material.wrap_rgb.copy(@wrap_rbg)

      material.map = @map

      material.light_map = @light_map

      material.specular_map = @specular_map

      material.alpha_map = @alpha_map

      material.env_map = @env_map
      material.combine = @combine
      material.reflectivity = @reflectivity
      material.refraction_ratio = @refraction_ratio

      material.fog = @fog

      material.shading = @shading

      material.wireframe = @wireframe
      material.wireframe_linewidth = @wireframe_linewidth
      material.wireframe_linecap = @wireframe_linecap
      material.wireframe_linejoin = @wireframe_linejoin

      material.vertex_colors = @vertex_colors

      material.skinning = @skinning
      material.morph_targets = @morph_targets
      material.morph_normals = @morph_normals

      material
    end
  end
end
