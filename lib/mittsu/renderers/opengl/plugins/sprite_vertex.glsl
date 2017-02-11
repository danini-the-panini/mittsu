#version 330

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float rotation;
uniform vec2 scale;
uniform vec2 uvOffset;
uniform vec2 uvScale;

in vec2 position;
in vec2 uv;

out vec2 vUV;

void main() {
  vUV = uvOffset + uv * uvScale;

  vec2 alignedPosition = position * scale;

  vec2 rotatedPosition;
  rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
  rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;

  vec4 finalPosition;

  finalPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );
  finalPosition.xy += rotatedPosition;
  finalPosition = projectionMatrix * finalPosition;

  gl_Position = finalPosition;
}
