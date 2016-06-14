require 'minitest_helper'

TEST_CHUNKS = {
  common: "#define PI 3.14159\n#define PI2 6.28318",
  something_else: "#define FOO 42\nfloat square( in float a ) { return a*a; }",
  some_vertex_library: "#define BAR 21\nvColor.xyz = inputToLinear( color.xyz );",
  some_fragment_library: "#define BAZ 10.5\ndiffuseColor.rgb *= vColor;"
}

TEST_UNIFORM_LIB = {
  common: {
    'commonFloat' => Mittsu::Uniform.new(:float, 1.2),
    'commonVectorArray' => Mittsu::Uniform.new(:'vec3[]', [Mittsu::Vector3.new(1.0, 2.0, 3.0), Mittsu::Vector3.new(4.0, 5.0, 6.0)]),
  },
  fog: {
    'fogDensity' => Mittsu::Uniform.new(:float, 0.00025),
    'fogNear' => Mittsu::Uniform.new(:float, 1.0),
    'fogFar' => Mittsu::Uniform.new(:float, 2000.0),
    'fogColor' => Mittsu::Uniform.new(:color, Mittsu::Color.new(0xffffff))
  }
}

TEST_UNIFORMS = <<RBSL
#include common
#include fog
RBSL

EXPECTED_UNIFORMS = {
  'commonFloat' => Mittsu::Uniform.new(:float, 1.2),
  'commonVectorArray' => Mittsu::Uniform.new(:'vec3[]', [Mittsu::Vector3.new(1.0, 2.0, 3.0), Mittsu::Vector3.new(4.0, 5.0, 6.0)]),
  'fogDensity' => Mittsu::Uniform.new(:float, 0.00025),
  'fogNear' => Mittsu::Uniform.new(:float, 1.0),
  'fogFar' => Mittsu::Uniform.new(:float, 2000.0),
  'fogColor' => Mittsu::Uniform.new(:color, Mittsu::Color.new(0xffffff))
}

TEST_CUSTOM_UNIFORMS = <<RBSL
#include common
uniform int someInt = 42;
uniform float someFloat = 123.45;
uniform vec3 someVector = vec3(1.2, 3.4, 5.6);
uniform color someColorRGB = color(0.5, 0.6, 0.7);
uniform color someColorEmpty = color();
uniform float[] someFloatArray = [1.0, 2.0, 3.0, 4.0];
uniform vec3[] someVectorArray = [
  vec3(1.0, 2.0, 3.0),
  vec3(2.0, 3.0, 4.0),
  vec3(3.0, 4.0, 5.0)
];
uniform mat4 someMatrix = mat4(
  1.0, 2.0, 3.0, 4.0,
  5.0, 6.0, 7.0, 8.0,
  9.0, 11.0, 12.0, 13.0,
  14.0, 15.0, 16.0, 17.0
);
uniform mat3[] someMatrixArray = [
  mat3(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
  mat3(2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0),
  mat3(3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0)
];
uniform vec3 someOtherVector;
uniform float someOtherFloat;
uniform vec3[] someOtherVectorArray;
uniform texture someTexture;
uniform texture[] someTextureArray;
RBSL


EXPECTED_CUSTOM_UNIFORMS = {
  'commonFloat' => Mittsu::Uniform.new(:float, 1.2),
  'commonVectorArray' => Mittsu::Uniform.new(:'vec3[]', [Mittsu::Vector3.new(1.0, 2.0, 3.0), Mittsu::Vector3.new(4.0, 5.0, 6.0)]),
  'someInt' => Mittsu::Uniform.new(:int, 42),
  'someFloat' => Mittsu::Uniform.new(:float, 123.45),
  'someVector' => Mittsu::Uniform.new(:vec3, Mittsu::Vector3.new(1.2, 3.4, 5.6)),
  'someColorRGB' => Mittsu::Uniform.new(:color, Mittsu::Color.new(0.5, 0.6, 0.7)),
  'someColorEmpty' => Mittsu::Uniform.new(:color, Mittsu::Color.new()),
  'someFloatArray' => Mittsu::Uniform.new(:'float[]', [1.0, 2.0, 3.0, 4.0]),
  'someVectorArray' => Mittsu::Uniform.new(:'vec3[]', [
    Mittsu::Vector3.new(1.0, 2.0, 3.0),
    Mittsu::Vector3.new(2.0, 3.0, 4.0),
    Mittsu::Vector3.new(3.0, 4.0, 5.0)
  ]),
  'someMatrix' => Mittsu::Uniform.new(:mat4, Mittsu::Matrix4.new.tap{|m| m.set(
    1.0, 2.0, 3.0, 4.0,
    5.0, 6.0, 7.0, 8.0,
    9.0, 11.0, 12.0, 13.0,
    14.0, 15.0, 16.0, 17.0
  )}),
  'someMatrixArray' => Mittsu::Uniform.new(:'mat3[]', [
    Mittsu::Matrix3.new.tap{|m| m.set(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0) },
    Mittsu::Matrix3.new.tap{|m| m.set(2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0) },
    Mittsu::Matrix3.new.tap{|m| m.set(3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0) }
  ]),
  'someOtherVector' => Mittsu::Uniform.new(:vec3, nil),
  'someOtherFloat' => Mittsu::Uniform.new(:float, nil),
  'someOtherVectorArray' => Mittsu::Uniform.new(:'vec3[]', []),
  'someTexture' => Mittsu::Uniform.new(:texture, nil),
  'someTextureArray' => Mittsu::Uniform.new(:'texture[]', [])
}

TEST_VERTEX = <<RBSL
uniform vec4 someUniform;

#include common
#include something_else

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #include some_vertex_library
}
RBSL

EXPECTED_VERTEX = <<RBSL
uniform vec4 someUniform;

#define PI 3.14159
#define PI2 6.28318
#define FOO 42
float square( in float a ) { return a*a; }

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #define BAR 21
  vColor.xyz = inputToLinear( color.xyz );
}
RBSL

TEST_FRAGMENT = <<RBSL
uniform vec4 someUniform;

#include common
#include something_else

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #include some_fragment_library

  fragColor = vec4(outgoingLight, diffuseColor.a);
}
RBSL

EXPECTED_FRAGMENT = <<RBSL
uniform vec4 someUniform;

#define PI 3.14159
#define PI2 6.28318
#define FOO 42
float square( in float a ) { return a*a; }

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #define BAZ 10.5
  diffuseColor.rgb *= vColor;

  fragColor = vec4(outgoingLight, diffuseColor.a);
}
RBSL

class TestRBSLLoader < Minitest::Test
  def assert_uniform(expected, actual, name)
    assert_kind_of(Mittsu::Uniform, actual, "#{name} is not a Uniform")
    assert_equal(expected.type, actual.type, "#{name} has the wrong type")
    assert_equal(expected.value, actual.value, "#{name} has the wrong value")
  end

  def test_load_shader
    loaded_shader = Mittsu::RBSLLoader.load_shader(TEST_VERTEX, TEST_CHUNKS)

    assert_equal(EXPECTED_VERTEX, loaded_shader)

    loaded_shader = Mittsu::RBSLLoader.load_shader(TEST_FRAGMENT, TEST_CHUNKS)

    assert_equal(EXPECTED_FRAGMENT, loaded_shader)
  end

  def test_load_uniforms
    loaded_uniforms = Mittsu::RBSLLoader.load_uniforms(TEST_UNIFORMS, TEST_UNIFORM_LIB)

    assert_equal(EXPECTED_UNIFORMS.keys.sort, loaded_uniforms.keys.sort)

    EXPECTED_UNIFORMS.keys.each do |key|
      assert_uniform(EXPECTED_UNIFORMS[key], loaded_uniforms[key], key)
    end
  end

  def test_load_custom_uniforms
    loaded_uniforms = Mittsu::RBSLLoader.load_uniforms(TEST_CUSTOM_UNIFORMS, TEST_UNIFORM_LIB)

    assert_equal(EXPECTED_CUSTOM_UNIFORMS.keys.sort, loaded_uniforms.keys.sort)

    EXPECTED_CUSTOM_UNIFORMS.keys.each do |key|
      assert_uniform(EXPECTED_CUSTOM_UNIFORMS[key], loaded_uniforms[key], key)
    end
  end
end
