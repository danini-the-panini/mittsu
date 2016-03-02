require 'mittsu/core/geometry'
require 'mittsu/core/object_3d'
require 'mittsu/objects'
require 'mittsu/materials'
require 'mittsu/textures'

require 'mittsu/renderers/opengl/core/opengl_geometry'
require 'mittsu/renderers/opengl/core/opengl_object_3d'
require 'mittsu/renderers/opengl/objects/opengl_mesh'
require 'mittsu/renderers/opengl/objects/opengl_line'
require 'mittsu/renderers/opengl/materials/opengl_material'
require 'mittsu/renderers/opengl/textures/opengl_texture'
require 'mittsu/renderers/opengl/textures/opengl_cube_texture'
require 'mittsu/renderers/opengl/textures/opengl_data_texture'
require 'mittsu/renderers/opengl/textures/opengl_compressed_texture'
require 'mittsu/renderers/opengl/lights/opengl_light'
require 'mittsu/renderers/opengl/lights/opengl_light'
require 'mittsu/renderers/opengl/lights/opengl_spot_light'
require 'mittsu/renderers/opengl/lights/opengl_point_light'
require 'mittsu/renderers/opengl/lights/opengl_hemisphere_light'
require 'mittsu/renderers/opengl/lights/opengl_ambient_light'
require 'mittsu/renderers/opengl/lights/opengl_directional_light'

module Mittsu
  OPENGL_IMPLEMENTATIONS = {
    Object3D => OpenGLObject3D,
    Geometry => OpenGLGeometry,
    Material => OpenGLMaterial,
    Texture => OpenGLTexture,
    Light => OpenGLLight,
    CubeTexture => OpenGLCubeTexture,
    Mesh => OpenGLMesh,
    Line => OpenGLLine,
    SpotLight => OpenGLSpotLight,
    PointLight => OpenGLPointLight,
    HemisphereLight => OpenGLHemisphereLight,
    AmbientLight => OpenGLAmbientLight,
    DirectionalLight => OpenGLDirectionalLight,
    DataTexture => OpenGLDataTexture,
    CompressedTexture => OpenGLCompressedTexture
  }
  OPENGL_IMPLEMENTATIONS.default_proc = -> (hash, key) {
    super_klass = key.ancestors.find { |a| hash.has_key?(a) }
    super_klass ? (hash[key] = hash[super_klass]) : nil
  }
end
