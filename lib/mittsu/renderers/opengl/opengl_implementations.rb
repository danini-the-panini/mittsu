require 'mittsu/core/geometry'
require 'mittsu/core/object_3d'
require 'mittsu/objects'
require 'mittsu/materials'
require 'mittsu/textures'
require 'mittsu/scenes'

require 'mittsu/renderers/opengl/core/geometry'
require 'mittsu/renderers/opengl/core/object_3d'
require 'mittsu/renderers/opengl/objects/mesh'
require 'mittsu/renderers/opengl/objects/line'
require 'mittsu/renderers/opengl/objects/group'
require 'mittsu/renderers/opengl/scenes/scene'

require 'mittsu/renderers/opengl/lights/light'
require 'mittsu/renderers/opengl/lights/spot_light'
require 'mittsu/renderers/opengl/lights/point_light'
require 'mittsu/renderers/opengl/lights/hemisphere_light'
require 'mittsu/renderers/opengl/lights/ambient_light'
require 'mittsu/renderers/opengl/lights/directional_light'

require 'mittsu/renderers/opengl/materials/material'
require 'mittsu/renderers/opengl/materials/mesh_basic_material'
require 'mittsu/renderers/opengl/materials/mesh_lambert_material'
require 'mittsu/renderers/opengl/materials/mesh_phong_material'
require 'mittsu/renderers/opengl/materials/line_basic_material'
require 'mittsu/renderers/opengl/materials/shader_material'

require 'mittsu/renderers/opengl/textures/opengl_texture'
require 'mittsu/renderers/opengl/textures/opengl_cube_texture'
require 'mittsu/renderers/opengl/textures/opengl_data_texture'
require 'mittsu/renderers/opengl/textures/opengl_compressed_texture'

module Mittsu
  OPENGL_IMPLEMENTATIONS = {
    Texture => OpenGLTexture,
    CubeTexture => OpenGLCubeTexture,
    DataTexture => OpenGLDataTexture,
    CompressedTexture => OpenGLCompressedTexture
  }
  OPENGL_IMPLEMENTATIONS.default_proc = -> (hash, key) {
    super_klass = key.ancestors.find { |a| hash.has_key?(a) }
    super_klass ? (hash[key] = hash[super_klass]) : nil
  }
end
