require 'mittsu/core/geometry'
require 'mittsu/core/object_3d'
require 'mittsu/objects'
require 'mittsu/materials'
require 'mittsu/textures'

module Mittsu
  OPENGL_IMPLEMENTATIONS = {
    Object3D => OpenGLObject3D,
    Geometry => OpenGLGeometry,
    Material => OpenGLMaterial,
    Texture => OpenGLTexture,
    CubeTexture => OpenGLCubeTexture,
    Mesh => OpenGLMesh,
    Line => OpenGLLine,
  }
  OPENGL_IMPLEMENTATIONS.default_proc = -> (hash, key) {
    super_klass = key.ancestors.find { |a| hash.has_key?(a) }
    super_klass ? (hash[key] = hash[super_klass]) : nil
  }
end
