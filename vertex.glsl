#version 330
#define VERTEX_TEXTURES
#define GAMMA_FACTOR 2.0
#define MAX_DIR_LIGHTS 0
#define MAX_POINT_LIGHTS 0
#define MAX_SPOT_LIGHTS 0
#define MAX_HEMI_LIGHTS 0
#define MAX_SHADOWS 0
#define MAX_BONES 251
#define USE_COLOR
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat3 normalMatrix;
uniform vec3 cameraPosition;
in vec3 position;
in vec3 normal;
in vec2 uv;
in vec2 uv2;
#ifdef USE_COLOR
  in vec3 color;
#endif
#ifdef USE_MORPHTARGETS
  in vec3 morphTarget0;
  in vec3 morphTarget1;
  in vec3 morphTarget2;
  in vec3 morphTarget3;
  #ifdef USE_MORPHNORMALS
    in vec3 morphNormal0;
    in vec3 morphNormal1;
    in vec3 morphNormal2;
    in vec3 morphNormal3;
  #else
    in vec3 morphTarget4;
    in vec3 morphTarget5;
    in vec3 morphTarget6;
    in vec3 morphTarget7;
  #endif
#endif
#ifdef USE_SKINNING
  in vec4 skinIndex;
  in vec4 skinWeight;
#endif
#define PI 3.14159
#define PI2 6.28318
#define RECIPROCAL_PI2 0.15915494
#define LOG2 1.442695
#define EPSILON 1e-6

float square( in float a ) { return a*a; }
vec2  square( in vec2 a )  { return vec2( a.x*a.x, a.y*a.y ); }
vec3  square( in vec3 a )  { return vec3( a.x*a.x, a.y*a.y, a.z*a.z ); }
vec4  square( in vec4 a )  { return vec4( a.x*a.x, a.y*a.y, a.z*a.z, a.w*a.w ); }
float saturate( in float a ) { return clamp( a, 0.0, 1.0 ); }
vec2  saturate( in vec2 a )  { return clamp( a, 0.0, 1.0 ); }
vec3  saturate( in vec3 a )  { return clamp( a, 0.0, 1.0 ); }
vec4  saturate( in vec4 a )  { return clamp( a, 0.0, 1.0 ); }
float average( in float a ) { return a; }
float average( in vec2 a )  { return ( a.x + a.y) * 0.5; }
float average( in vec3 a )  { return ( a.x + a.y + a.z) / 3.0; }
float average( in vec4 a )  { return ( a.x + a.y + a.z + a.w) * 0.25; }
float whiteCompliment( in float a ) { return saturate( 1.0 - a ); }
vec2  whiteCompliment( in vec2 a )  { return saturate( vec2(1.0) - a ); }
vec3  whiteCompliment( in vec3 a )  { return saturate( vec3(1.0) - a ); }
vec4  whiteCompliment( in vec4 a )  { return saturate( vec4(1.0) - a ); }
vec3 transformDirection( in vec3 normal, in mat4 matrix ) {
	return normalize( ( matrix * vec4( normal, 0.0 ) ).xyz );
}
// http://en.wikibooks.org/wiki/GLSL_Programming/Applying_Matrix_Transformations
vec3 inverseTransformDirection( in vec3 normal, in mat4 matrix ) {
	return normalize( ( vec4( normal, 0.0 ) * matrix ).xyz );
}
vec3 projectOnPlane(in vec3 point, in vec3 pointOnPlane, in vec3 planeNormal) {
	float distance = dot( planeNormal, point-pointOnPlane );
	return point - distance * planeNormal;
}
float sideOfPlane( in vec3 point, in vec3 pointOnPlane, in vec3 planeNormal ) {
	return sign( dot( point - pointOnPlane, planeNormal ) );
}
vec3 linePlaneIntersect( in vec3 pointOnLine, in vec3 lineDirection, in vec3 pointOnPlane, in vec3 planeNormal ) {
	return pointOnLine + lineDirection * ( dot( planeNormal, pointOnPlane - pointOnLine ) / dot( planeNormal, lineDirection ) );
}
float calcLightAttenuation( float lightDistance, float cutoffDistance, float decayExponent ) {
	if ( decayExponent > 0.0 ) {
	  return pow( saturate( 1.0 - lightDistance / cutoffDistance ), decayExponent );
	}
	return 1.0;
}

vec3 inputToLinear( in vec3 a ) {
#ifdef GAMMA_INPUT
	return pow( a, vec3( float( GAMMA_FACTOR ) ) );
#else
	return a;
#endif
}
vec3 linearToOutput( in vec3 a ) {
#ifdef GAMMA_OUTPUT
	return pow( a, vec3( 1.0 / float( GAMMA_FACTOR ) ) );
#else
	return a;
#endif
}

#if defined( USE_MAP ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( USE_SPECULARMAP ) || defined( USE_ALPHAMAP )

	out vec2 vUv;
	uniform vec4 offsetRepeat;

#endif

#ifdef USE_LIGHTMAP

	out vec2 vUv2;

#endif
#if defined( USE_ENVMAP ) && ! defined( USE_BUMPMAP ) && ! defined( USE_NORMALMAP ) && ! defined( PHONG )

	out vec3 vReflect;

	uniform float refractionRatio;

#endif

#ifdef USE_COLOR

	out vec3 vColor;

#endif

#ifdef USE_MORPHTARGETS

	#ifndef USE_MORPHNORMALS

	uniform float morphTargetInfluences[ 8 ];

	#else

	uniform float morphTargetInfluences[ 4 ];

	#endif

#endif
#ifdef USE_SKINNING

	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;

	#ifdef BONE_TEXTURE

		uniform sampler2D boneTexture;
		uniform int boneTextureWidth;
		uniform int boneTextureHeight;

		mat4 getBoneMatrix( const in float i ) {

			float j = i * 4.0;
			float x = mod( j, float( boneTextureWidth ) );
			float y = floor( j / float( boneTextureWidth ) );

			float dx = 1.0 / float( boneTextureWidth );
			float dy = 1.0 / float( boneTextureHeight );

			y = dy * ( y + 0.5 );

			vec4 v1 = texture2D( boneTexture, vec2( dx * ( x + 0.5 ), y ) );
			vec4 v2 = texture2D( boneTexture, vec2( dx * ( x + 1.5 ), y ) );
			vec4 v3 = texture2D( boneTexture, vec2( dx * ( x + 2.5 ), y ) );
			vec4 v4 = texture2D( boneTexture, vec2( dx * ( x + 3.5 ), y ) );

			mat4 bone = mat4( v1, v2, v3, v4 );

			return bone;

		}

	#else

		uniform mat4 boneGlobalMatrices[ MAX_BONES ];

		mat4 getBoneMatrix( const in float i ) {

			mat4 bone = boneGlobalMatrices[ int(i) ];
			return bone;

		}

	#endif

#endif

#ifdef USE_SHADOWMAP

	out vec4 vShadowCoord[ MAX_SHADOWS ];
	uniform mat4 shadowMatrix[ MAX_SHADOWS ];

#endif
#ifdef USE_LOGDEPTHBUF

	#ifdef USE_LOGDEPTHBUF_EXT

		out float vFragDepth;

	#endif

	uniform float logDepthBufFC;

#endif
void main() {
#if defined( USE_MAP ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( USE_SPECULARMAP ) || defined( USE_ALPHAMAP )

	vUv = uv * offsetRepeat.zw + offsetRepeat.xy;

#endif
#ifdef USE_LIGHTMAP

	vUv2 = uv2;

#endif
#ifdef USE_COLOR

	vColor.xyz = inputToLinear( color.xyz );

#endif
#ifdef USE_SKINNING

	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );

#endif
  #ifdef USE_ENVMAP
#ifdef USE_MORPHNORMALS

	vec3 morphedNormal = vec3( 0.0 );

	morphedNormal += ( morphNormal0 - normal ) * morphTargetInfluences[ 0 ];
	morphedNormal += ( morphNormal1 - normal ) * morphTargetInfluences[ 1 ];
	morphedNormal += ( morphNormal2 - normal ) * morphTargetInfluences[ 2 ];
	morphedNormal += ( morphNormal3 - normal ) * morphTargetInfluences[ 3 ];

	morphedNormal += normal;

#endif
#ifdef USE_SKINNING

	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix  = bindMatrixInverse * skinMatrix * bindMatrix;

	#ifdef USE_MORPHNORMALS

	vec4 skinnedNormal = skinMatrix * vec4( morphedNormal, 0.0 );

	#else

	vec4 skinnedNormal = skinMatrix * vec4( normal, 0.0 );

	#endif

#endif

#ifdef USE_SKINNING

	vec3 objectNormal = skinnedNormal.xyz;

#elif defined( USE_MORPHNORMALS )

	vec3 objectNormal = morphedNormal;

#else

	vec3 objectNormal = normal;

#endif

#ifdef FLIP_SIDED

	objectNormal = -objectNormal;

#endif

vec3 transformedNormal = normalMatrix * objectNormal;

  #endif
#ifdef USE_MORPHTARGETS

	vec3 morphed = vec3( 0.0 );
	morphed += ( morphTarget0 - position ) * morphTargetInfluences[ 0 ];
	morphed += ( morphTarget1 - position ) * morphTargetInfluences[ 1 ];
	morphed += ( morphTarget2 - position ) * morphTargetInfluences[ 2 ];
	morphed += ( morphTarget3 - position ) * morphTargetInfluences[ 3 ];

	#ifndef USE_MORPHNORMALS

	morphed += ( morphTarget4 - position ) * morphTargetInfluences[ 4 ];
	morphed += ( morphTarget5 - position ) * morphTargetInfluences[ 5 ];
	morphed += ( morphTarget6 - position ) * morphTargetInfluences[ 6 ];
	morphed += ( morphTarget7 - position ) * morphTargetInfluences[ 7 ];

	#endif

	morphed += position;

#endif

#ifdef USE_SKINNING

	vec4 mvPosition = modelViewMatrix * skinned;

#elif defined( USE_MORPHTARGETS )

	vec4 mvPosition = modelViewMatrix * vec4( morphed, 1.0 );

#else

	vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );

#endif

gl_Position = projectionMatrix * mvPosition;

#ifdef USE_LOGDEPTHBUF

	gl_Position.z = log2(max( EPSILON, gl_Position.w + 1.0 )) * logDepthBufFC;

	#ifdef USE_LOGDEPTHBUF_EXT

		vFragDepth = 1.0 + gl_Position.w;

#else

		gl_Position.z = (gl_Position.z - 1.0) * gl_Position.w;

	#endif

#endif
#if defined( USE_ENVMAP ) || defined( PHONG ) || defined( LAMBERT ) || defined ( USE_SHADOWMAP )

	#ifdef USE_SKINNING

		vec4 worldPosition = modelMatrix * skinned;

	#elif defined( USE_MORPHTARGETS )

		vec4 worldPosition = modelMatrix * vec4( morphed, 1.0 );

	#else

		vec4 worldPosition = modelMatrix * vec4( position, 1.0 );

	#endif

#endif

#if defined( USE_ENVMAP ) && ! defined( USE_BUMPMAP ) && ! defined( USE_NORMALMAP ) && ! defined( PHONG )

	vec3 worldNormal = transformDirection( objectNormal, modelMatrix );

	vec3 cameraToVertex = normalize( worldPosition.xyz - cameraPosition );

	#ifdef ENVMAP_MODE_REFLECTION

		vReflect = reflect( cameraToVertex, worldNormal );

	#else

		vReflect = refract( cameraToVertex, worldNormal, refractionRatio );

	#endif

#endif

#ifdef USE_SHADOWMAP

	for( int i = 0; i < MAX_SHADOWS; i ++ ) {

		vShadowCoord[ i ] = shadowMatrix[ i ] * worldPosition;

	}

#endif
}