# @author alteredq / http://alteredqualia.com/
#
#  parameters = {
#    defines: { "label" : "value" },
#    uniforms: { "parameter1": { type: "f", value: 1.0 }, "parameter2": { type: "i" value2: 2 } },
#
#    fragmentShader: <string>,
#    vertexShader: <string>,
#
#    shading: THREE.SmoothShading,
#    blending: THREE.NormalBlending,
#    depthTest: <bool>,
#    depthWrite: <bool>,
#
#    wireframe: <boolean>,
#    wireframeLinewidth: <float>,
#
#    lights: <bool>,
#
#    vertexColors: THREE.NoColors / THREE.VertexColors / THREE.FaceColors,
#
#    skinning: <bool>,
#    morphTargets: <bool>,
#    morphNormals: <bool>,
#
#  	 fog: <bool>
#  }

module Mittsu
  class ShaderMaterial < Material
    attr_accessor :fragment_shader, :vertex_shader, :attributes, :defines, :shading, :wireframe, :wireframe_linewidth, :fog, :lights, :vertex_colors, :skinning, :morph_targets, :morph_normals

    def initialize(parameters = {})
      super()

      @type = 'ShaderMaterial'
      @defines = {}
      @uniforms = {}
      @attributes = nil

      @vertex_shader = 'void main() {\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}'
      @fragment_shader = 'void main() {\n\tgl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );\n}'

      @shading = SmoothShading

      @line_width = 1

      @wireframe = false
      @wireframe_linewidth = 1

      @fog = false # set to use scene fog

      @lights = false # set to use scene lights

      @vertex_colors = NoColors # set to use "color" attribute stream

      @skinning = false # set to use skinning attribute streams

      @morph_targets = false # set to use morph targets
      @morph_normals = false # set to use morph normals

	    # When rendered geometry doesn't include these attributes but the material does,
	    # use these default values in WebGL. This avoids errors when buffer data is missing.
      @default_attributes_values = {
        'color' => [1.0, 1.0, 1.0],
        'uv' => [0, 0],
        'uv2' => [0, 0]
      }

      # TODO: necessary?
    	# this.index0AttributeName = undefined;

      self.set_values(parameters)
    end

    def clone
      material = ShaderMaterial.new

      super.clone(material)

    	material.fragment_shader = @fragment_shader
    	material.vertex_shader = @vertex_shader

    	material.uniforms = UniformsUtils.clone(@uniforms)

    	material.attributes = @attributes
    	material.defines = @defines

    	material.shading = @shading

    	material.wireframe = @wireframe
    	material.wireframe_linewidth = @wireframe_linewidth

    	material.fog = @fog

    	material.lights = @lights

    	material.vertex_colors = @vertex_colors

    	material.skinning = @skinning

    	material.morph_targets = @morph_targets
    	material.morph_normals = @morph_normals

	    material
    end
  end
end
