require 'mittsu/math'
require 'mittsu/core/hash_object'

module Mittsu
  class Uniform < HashObject
    attr_accessor :type, :value, :needs_update

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
      'diffuse' => Uniform.new(:c, Color.new(0xeeeeee)),
      'opacity' => Uniform.new(:f, 1.0),

      'map' => Uniform.new(:t, nil),
      'offsetRepeat' => Uniform.new(:v4, Vector4.new(0.0, 0.0, 1.0, 1.0)),

      'lightMap' => Uniform.new(:t, nil),
      'specularMap' => Uniform.new(:t, nil),
      'alphaMap' => Uniform.new(:t, nil),

      'envMap' => Uniform.new(:t, nil),
      'flipEnvMap' => Uniform.new(:f, -1.0),
      'reflectivity' => Uniform.new(:f, 1.0),
      'refractionRatio' => Uniform.new(:f, 0.98),

      'morphTargetInfluences' => Uniform.new(:f, 0.0)
    },

    bump: {
      'bumpMap' => Uniform.new(:t, nil),
      'bumpScale' => Uniform.new(:f, 1.0)
    },

  	normal_map: {
  		'normalMap' => Uniform.new(:t, nil),
  		'normalScale' => Uniform.new(:v2, Vector2.new(1.0, 1.0))
  	},

    fog: {
      'fogDensity' => Uniform.new(:f, 0.00025),
      'fogNear' => Uniform.new(:f, 1.0),
      'fogFar' => Uniform.new(:f, 2000.0),
      'fogColor' => Uniform.new(:c, Color.new(0xffffff))
    },

    lights: {
      'ambientLightColor' => Uniform.new(:fv, []),

      'directionalLightDirection' => Uniform.new(:fv, []),
      'directionalLightColor' => Uniform.new(:fv, []),

      'hemisphereLightDirection' => Uniform.new(:fv, []),
      'hemisphereLightSkyColor' => Uniform.new(:fv, []),
      'hemisphereLightGroundColor' => Uniform.new(:fv, []),

      'pointLightColor' => Uniform.new(:fv, []),
      'pointLightPosition' => Uniform.new(:fv, []),
      'pointLightDistance' => Uniform.new(:fv1, []),
      'pointLightDecay' => Uniform.new(:fv1, []),

      'spotLightColor' => Uniform.new(:fv, []),
      'spotLightPosition' => Uniform.new(:fv, []),
      'spotLightDirection' => Uniform.new(:fv, []),
      'spotLightDistance' => Uniform.new(:fv, []),
      'spotLightAngleCos' => Uniform.new(:fv, []),
      'spotLightExponent' => Uniform.new(:fv, []),
      'spotLightDecay' => Uniform.new(:fv, [])
    },

    particle: {
      'psColor' => Uniform.new(:c, Color.new(0xeeeeee)),
      'opacity' => Uniform.new(:f, 1.0),
      'size' => Uniform.new(:f, 1.0),
      'scale' => Uniform.new(:f, 1.0),
      'map' => Uniform.new(:t, nil),
      'offsetRepeat' => Uniform.new(:v4, Vector4.new(0.0, 0.0, 1.0, 1.0))
    },

    shadow_map: {
      'shadowMap' => Uniform.new(:tv, []),
      'shadowMapSize' => Uniform.new(:v2v, []),

      'shadowBias' => Uniform.new(:fv1, []),
      'shadowDarkness' => Uniform.new(:fv1, []),

      'shadowMatrix' => Uniform.new(:m4v, [])
    }
  }
end
