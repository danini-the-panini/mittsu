#  parameters = {
#   color: <hex>,
#   emissive: <hex>,
#   specular: <hex>,
#   shininess: <float>,
#   opacity: <float>,
#
#   map: Texture.new(<Image>),
#
#   lightMap: Texture.new(<Image>),
#
#   bumpMap: Texture.new(<Image>),
#   bumpScale: <float>,
#
#   normalMap: Texture.new(<Image>),
#   normalScale: <Vector2>,
#
#   specularMap: Texture.new(<Image>),
#
#   alphaMap: Texture.new(<Image>),
#
#   envMap: TextureCube.new([posx, negx, posy, negy, posz, negz]),
#   combine: Multiply,
#   reflectivity: <float>,
#   refractionRatio: <float>,
#
#   shading: SmoothShading,
#   blending: NormalBlending,
#   depthTest: <bool>,
#   depthWrite: <bool>,
#
#   wireframe: <boolean>,
#   wireframeLinewidth: <float>,
#
#   vertexColors: NoColors / VertexColors / FaceColors,
#
#   skinning: <bool>,
#   morphTargets: <bool>,
#   morphNormals: <bool>,
#
# 	fog: <bool>
#  }

module Mittsu
  class MeshPhongMaterial < Material
    attr_accessor :normal_scale, :shininess, :emissive, :specular

    def initialize(parameters = {})
      super()

    	@type = 'MeshPhongMaterial'

    	@color = Color.new(0xffffff) # diffuse
    	@emissive = Color.new(0x000000)
    	@specular = Color.new(0x111111)
    	@shininess = 30.0

    	@metal = false

    	@wrap_around = false
    	@wrap_rgb = Vector3.new(1.0, 1.0, 1.0)

    	@map = nil

    	@light_map = nil

    	@bump_map = nil
    	@bump_scale = 1.0

    	@normal_map = nil
    	@normal_scale = Vector2.new(1.0, 1.0)

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
    	@wireframe_linecap = 'round'
    	@wireframe_linejoin = 'round'

    	@vertex_colors = NoColors

    	@skinning = false
    	@morph_targets = false
    	@morph_normals = false

    	self.set_values(parameters)
    end

    def clone
      material = MeshPhongMaterial.new

      super(material)

    	material.color.copy(@color)
    	material.emissive.copy(@emissive)
    	material.specular.copy(@specular)
    	material.shininess = @shininess

    	material.metal = @metal

    	material.wrap_around = @wrap_around
    	material.wrap_rgb.copy(@wrap_rgb)

    	material.map = @map

    	material.light_map = @light_map

    	material.bump_map = @bump_map
    	material.bump_scale = @bump_scale

    	material.normal_map = @normal_map
    	material.normal_scale.copy(@normal_scale)

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
