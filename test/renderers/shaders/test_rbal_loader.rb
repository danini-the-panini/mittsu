require 'minitest_helper'

TEST_CHUNKS = {
  common: "#define PI 3.14159\n#define PI2 6.28318",
  something_else: "#define FOO 42\nfloat square( in float a ) { return a*a; }",
  some_vertex_library: "#define BAR 21\nvColor.xyz = inputToLinear( color.xyz );",
  some_fragment_library: "#define BAZ 10.5\ndiffuseColor.rgb *= vColor;"
}

TEST_UNIFORM_LIB = {
  common: :COMMON_UNIFORM_STUB,
  fog: :FOG_UNIFORM_STUB
}

TEST_UNIFORMS = <<RBSL
#rb_include common
#rb_include fog
RBSL

EXPECTED_UNIFORMS = [
  :COMMON_UNIFORM_STUB,
  :FOG_UNIFORM_STUB
]

TEST_VERTEX = <<RBSL
uniform vec4 someUniform;

#rb_include common
#rb_include something_else

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #rb_include some_vertex_library
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

#rb_include common
#rb_include something_else

void main() {
  vec4 someVariable = vec4(1, 0, 0.5, 1.0);

  #rb_include some_fragment_library

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
  def test_load_shader
    loaded_shader = Mittsu::RBSLLoader.load_shader(TEST_VERTEX, TEST_CHUNKS)

    assert_equal(EXPECTED_VERTEX, loaded_shader)

    loaded_shader = Mittsu::RBSLLoader.load_shader(TEST_FRAGMENT, TEST_CHUNKS)

    assert_equal(EXPECTED_FRAGMENT, loaded_shader)
  end

  def test_load_uniforms
    loaded_uniforms = Mittsu::RBSLLoader.load_uniforms(TEST_UNIFORMS, TEST_UNIFORM_LIB)

    assert_equal(EXPECTED_UNIFORMS, loaded_uniforms)
  end
end
