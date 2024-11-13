require 'mittsu/math'

module Mittsu
  class Uniform
    attr_accessor :type, :value, :needs_update, :array

    def initialize(type, value)
      super()
      @type, @value = type, value
      @needs_update = nil
    end

    def clone
      new_value = case self.value
      when Color, Vector2, Vector3, Vector4, Matrix4#, Texture # TODO: when Texture exists
        self.value.clone
      when Array
        self.value.dup
      else
        self.value
      end
      Uniform.new(self.type, new_value)
    end
  end

  UniformsLib = {
    common: {
      'diffuse' => Uniform.new(:color, Color.new(0xeeeeee)),
      'opacity' => Uniform.new(:float, 1.0),

      'map' => Uniform.new(:texture, nil),
      'offsetRepeat' => Uniform.new(:vec4, Vector4.new(0.0, 0.0, 1.0, 1.0)),

      'lightMap' => Uniform.new(:texture, nil),
      'specularMap' => Uniform.new(:texture, nil),
      'alphaMap' => Uniform.new(:texture, nil),

      'envMap' => Uniform.new(:texture, nil),
      'flipEnvMap' => Uniform.new(:float, -1.0),
      'reflectivity' => Uniform.new(:float, 1.0),
      'refractionRatio' => Uniform.new(:float, 0.98),

      'morphTargetInfluences' => Uniform.new(:float, 0.0)
    },

    bump: {
      'bumpMap' => Uniform.new(:texture, nil),
      'bumpScale' => Uniform.new(:float, 1.0)
    },

  	normal_map: {
  		'normalMap' => Uniform.new(:texture, nil),
  		'normalScale' => Uniform.new(:vec2, Vector2.new(1.0, 1.0))
  	},

    fog: {
      'fogDensity' => Uniform.new(:float, 0.00025),
      'fogNear' => Uniform.new(:float, 1.0),
      'fogFar' => Uniform.new(:float, 2000.0),
      'fogColor' => Uniform.new(:color, Color.new(0xffffff))
    },

    lights: {
      'ambientLightColor' => Uniform.new(:color, Color.new(0xffffff)),

      'directionalLightDirection' => Uniform.new(:'vec3[]', []),
      'directionalLightColor' => Uniform.new(:'color[]', []),

      'hemisphereLightDirection' => Uniform.new(:'vec3[]', []),
      'hemisphereLightSkyColor' => Uniform.new(:'color[]', []),
      'hemisphereLightGroundColor' => Uniform.new(:'color[]', []),

      'pointLightColor' => Uniform.new(:'color[]', []),
      'pointLightPosition' => Uniform.new(:'vec3[]', []),
      'pointLightDistance' => Uniform.new(:'float[]', []),
      'pointLightDecay' => Uniform.new(:'float[]', []),

      'spotLightColor' => Uniform.new(:'color[]', []),
      'spotLightPosition' => Uniform.new(:'vec3[]', []),
      'spotLightDirection' => Uniform.new(:'vec3[]', []),
      'spotLightDistance' => Uniform.new(:'float[]', []),
      'spotLightAngleCos' => Uniform.new(:'float[]', []),
      'spotLightExponent' => Uniform.new(:'float[]', []),
      'spotLightDecay' => Uniform.new(:'float[]', [])
    },

    particle: {
      'psColor' => Uniform.new(:color, Color.new(0xeeeeee)),
      'opacity' => Uniform.new(:float, 1.0),
      'size' => Uniform.new(:float, 1.0),
      'scale' => Uniform.new(:float, 1.0),
      'map' => Uniform.new(:texture, nil),
      'offsetRepeat' => Uniform.new(:vec4, Vector4.new(0.0, 0.0, 1.0, 1.0))
    },

    shadow_map: {
      'shadowMap' => Uniform.new(:'texture[]', []),
      'shadowMapSize' => Uniform.new(:'vec2[]', []),

      'shadowBias' => Uniform.new(:'float[]', []),
      'shadowDarkness' => Uniform.new(:'float[]', []),

      'shadowMatrix' => Uniform.new(:'mat4[]', [])
    }
  }
end
