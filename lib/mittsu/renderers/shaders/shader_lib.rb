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

    def self.load_from_file(name)
      ShaderLib_Instance.new(
        uniforms: RBSLLoader.load_uniforms(File.read(File.join(__dir__, 'shader_lib', name, "#{name}_uniforms.rbslu")), UniformsLib),
        vertex_shader: RBSLLoader.load_shader(File.read(File.join(__dir__, 'shader_lib', name, "#{name}_vertex.rbsl")), ShaderChunk),
        fragment_shader: RBSLLoader.load_shader(File.read(File.join(__dir__, 'shader_lib', name, "#{name}_fragment.rbsl")), ShaderChunk)
      )
    end
  end
  private_constant :ShaderLib_Instance

  SHADER_LIB_HASH = Hash.new { |h, k|
    h[k] = ShaderLib_Instance.load_from_file(k.to_s)
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
