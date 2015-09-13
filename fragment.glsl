#version 330
#define MAX_DIR_LIGHTS 0
#define MAX_POINT_LIGHTS 0
#define MAX_SPOT_LIGHTS 0
#define MAX_HEMI_LIGHTS 0
#define MAX_SHADOWS 0
#define ALPHATEST 0.0
#define GAMMA_FACTOR 2.0
#define USE_COLOR
uniform mat4 viewMatrix;
uniform vec3 cameraPosition;
out vec4 fragColor;
uniform vec3 diffuse;
uniform float opacity;
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

#ifdef USE_COLOR

	in vec3 vColor;

#endif

#if defined( USE_MAP ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( USE_SPECULARMAP ) || defined( USE_ALPHAMAP )

	in vec2 vUv;

#endif

#ifdef USE_MAP

	uniform sampler2D map;

#endif
#ifdef USE_ALPHAMAP

	uniform sampler2D alphaMap;

#endif

#ifdef USE_LIGHTMAP

	in vec2 vUv2;
	uniform sampler2D lightMap;

#endif

#ifdef USE_ENVMAP

	uniform float reflectivity;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	uniform float flipEnvMap;

	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG )

		uniform float refractionRatio;

	#else

		in vec3 vReflect;

	#endif

#endif

#ifdef USE_FOG

	uniform vec3 fogColor;

	#ifdef FOG_EXP2

		uniform float fogDensity;

	#else

		uniform float fogNear;
		uniform float fogFar;
	#endif

#endif
#ifdef USE_SHADOWMAP

	uniform sampler2D shadowMap[ MAX_SHADOWS ];
	uniform vec2 shadowMapSize[ MAX_SHADOWS ];

	uniform float shadowDarkness[ MAX_SHADOWS ];
	uniform float shadowBias[ MAX_SHADOWS ];

	in vec4 vShadowCoord[ MAX_SHADOWS ];

	float unpackDepth( const in vec4 rgba_depth ) {

		const vec4 bit_shift = vec4( 1.0 / ( 256.0 * 256.0 * 256.0 ), 1.0 / ( 256.0 * 256.0 ), 1.0 / 256.0, 1.0 );
		float depth = dot( rgba_depth, bit_shift );
		return depth;

	}

#endif
#ifdef USE_SPECULARMAP

	uniform sampler2D specularMap;

#endif
#ifdef USE_LOGDEPTHBUF

	uniform float logDepthBufFC;

	#ifdef USE_LOGDEPTHBUF_EXT

		#extension GL_EXT_frag_depth : enable
		in float vFragDepth;

	#endif

#endif
void main() {
  vec3 outgoingLight = vec3( 0.0 );
  vec4 diffuseColor = vec4( diffuse, opacity );
#if defined(USE_LOGDEPTHBUF) && defined(USE_LOGDEPTHBUF_EXT)

	gl_FragDepthEXT = log2(vFragDepth) * logDepthBufFC * 0.5;

#endif
#ifdef USE_MAP

	vec4 texelColor = texture2D( map, vUv );

	texelColor.xyz = inputToLinear( texelColor.xyz );

	diffuseColor *= texelColor;

#endif
#ifdef USE_COLOR

	diffuseColor.rgb *= vColor;

#endif
#ifdef USE_ALPHAMAP

	diffuseColor.a *= texture2D( alphaMap, vUv ).g;

#endif

#ifdef ALPHATEST

	if ( diffuseColor.a < ALPHATEST ) discard;

#endif

float specularStrength;

#ifdef USE_SPECULARMAP

	vec4 texelSpecular = texture2D( specularMap, vUv );
	specularStrength = texelSpecular.r;

#else

	specularStrength = 1.0;

#endif
  outgoingLight = diffuseColor.rgb;
#ifdef USE_LIGHTMAP

	outgoingLight *= diffuseColor.xyz * texture2D( lightMap, vUv2 ).xyz;

#endif
#ifdef USE_ENVMAP

	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG )

		vec3 cameraToVertex = normalize( vWorldPosition - cameraPosition );

		// Transforming Normal Vectors with the Inverse Transformation
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );

		#ifdef ENVMAP_MODE_REFLECTION

			vec3 reflectVec = reflect( cameraToVertex, worldNormal );

		#else

			vec3 reflectVec = refract( cameraToVertex, worldNormal, refractionRatio );

		#endif

	#else

		vec3 reflectVec = vReflect;

	#endif

	#ifdef DOUBLE_SIDED
		float flipNormal = ( -1.0 + 2.0 * float( gl_FrontFacing ) );
	#else
		float flipNormal = 1.0;
	#endif

	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, flipNormal * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );

	#elif defined( ENVMAP_TYPE_EQUIREC )
		vec2 sampleUV;
		sampleUV.y = saturate( flipNormal * reflectVec.y * 0.5 + 0.5 );
		sampleUV.x = atan( flipNormal * reflectVec.z, flipNormal * reflectVec.x ) * RECIPROCAL_PI2 + 0.5;
		vec4 envColor = texture2D( envMap, sampleUV );

	#elif defined( ENVMAP_TYPE_SPHERE )
		vec3 reflectView = flipNormal * normalize((viewMatrix * vec4( reflectVec, 0.0 )).xyz + vec3(0.0,0.0,1.0));
		vec4 envColor = texture2D( envMap, reflectView.xy * 0.5 + 0.5 );
	#endif

	envColor.xyz = inputToLinear( envColor.xyz );

	#ifdef ENVMAP_BLENDING_MULTIPLY

		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );

	#elif defined( ENVMAP_BLENDING_MIX )

		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );

	#elif defined( ENVMAP_BLENDING_ADD )

		outgoingLight += envColor.xyz * specularStrength * reflectivity;

	#endif

#endif

#ifdef USE_SHADOWMAP

	#ifdef SHADOWMAP_DEBUG

		vec3 frustumColors[3];
		frustumColors[0] = vec3( 1.0, 0.5, 0.0 );
		frustumColors[1] = vec3( 0.0, 1.0, 0.8 );
		frustumColors[2] = vec3( 0.0, 0.5, 1.0 );

	#endif

	#ifdef SHADOWMAP_CASCADE

		int inFrustumCount = 0;

	#endif

	float fDepth;
	vec3 shadowColor = vec3( 1.0 );

	for( int i = 0; i < MAX_SHADOWS; i ++ ) {

		vec3 shadowCoord = vShadowCoord[ i ].xyz / vShadowCoord[ i ].w;

				// if ( something && something ) breaks ATI OpenGL shader compiler
				// if ( all( something, something ) ) using this instead

		bvec4 inFrustumVec = bvec4 ( shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0 );
		bool inFrustum = all( inFrustumVec );

				// don't shadow pixels outside of light frustum
				// use just first frustum (for cascades)
				// don't shadow pixels behind far plane of light frustum

		#ifdef SHADOWMAP_CASCADE

			inFrustumCount += int( inFrustum );
			bvec3 frustumTestVec = bvec3( inFrustum, inFrustumCount == 1, shadowCoord.z <= 1.0 );

		#else

			bvec2 frustumTestVec = bvec2( inFrustum, shadowCoord.z <= 1.0 );

		#endif

		bool frustumTest = all( frustumTestVec );

		if ( frustumTest ) {

			shadowCoord.z += shadowBias[ i ];

			#if defined( SHADOWMAP_TYPE_PCF )

						// Percentage-close filtering
						// (9 pixel kernel)
						// http://fabiensanglard.net/shadowmappingPCF/

				float shadow = 0.0;

		/*
						// nested loops breaks shader compiler / validator on some ATI cards when using OpenGL
						// must enroll loop manually

				for ( float y = -1.25; y <= 1.25; y += 1.25 )
					for ( float x = -1.25; x <= 1.25; x += 1.25 ) {

						vec4 rgbaDepth = texture2D( shadowMap[ i ], vec2( x * xPixelOffset, y * yPixelOffset ) + shadowCoord.xy );

								// doesn't seem to produce any noticeable visual difference compared to simple texture2D lookup
								//vec4 rgbaDepth = texture2DProj( shadowMap[ i ], vec4( vShadowCoord[ i ].w * ( vec2( x * xPixelOffset, y * yPixelOffset ) + shadowCoord.xy ), 0.05, vShadowCoord[ i ].w ) );

						float fDepth = unpackDepth( rgbaDepth );

						if ( fDepth < shadowCoord.z )
							shadow += 1.0;

				}

				shadow /= 9.0;

		*/

				const float shadowDelta = 1.0 / 9.0;

				float xPixelOffset = 1.0 / shadowMapSize[ i ].x;
				float yPixelOffset = 1.0 / shadowMapSize[ i ].y;

				float dx0 = -1.25 * xPixelOffset;
				float dy0 = -1.25 * yPixelOffset;
				float dx1 = 1.25 * xPixelOffset;
				float dy1 = 1.25 * yPixelOffset;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ) ) );
				if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				shadowColor = shadowColor * vec3( ( 1.0 - shadowDarkness[ i ] * shadow ) );

			#elif defined( SHADOWMAP_TYPE_PCF_SOFT )

						// Percentage-close filtering
						// (9 pixel kernel)
						// http://fabiensanglard.net/shadowmappingPCF/

				float shadow = 0.0;

				float xPixelOffset = 1.0 / shadowMapSize[ i ].x;
				float yPixelOffset = 1.0 / shadowMapSize[ i ].y;

				float dx0 = -1.0 * xPixelOffset;
				float dy0 = -1.0 * yPixelOffset;
				float dx1 = 1.0 * xPixelOffset;
				float dy1 = 1.0 * yPixelOffset;

				mat3 shadowKernel;
				mat3 depthKernel;

				depthKernel[0][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ) ) );
				depthKernel[0][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ) ) );
				depthKernel[0][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ) ) );
				depthKernel[1][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ) ) );
				depthKernel[1][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy ) );
				depthKernel[1][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ) ) );
				depthKernel[2][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ) ) );
				depthKernel[2][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ) ) );
				depthKernel[2][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ) ) );

				vec3 shadowZ = vec3( shadowCoord.z );
				shadowKernel[0] = vec3(lessThan(depthKernel[0], shadowZ ));
				shadowKernel[0] *= vec3(0.25);

				shadowKernel[1] = vec3(lessThan(depthKernel[1], shadowZ ));
				shadowKernel[1] *= vec3(0.25);

				shadowKernel[2] = vec3(lessThan(depthKernel[2], shadowZ ));
				shadowKernel[2] *= vec3(0.25);

				vec2 fractionalCoord = 1.0 - fract( shadowCoord.xy * shadowMapSize[i].xy );

				shadowKernel[0] = mix( shadowKernel[1], shadowKernel[0], fractionalCoord.x );
				shadowKernel[1] = mix( shadowKernel[2], shadowKernel[1], fractionalCoord.x );

				vec4 shadowValues;
				shadowValues.x = mix( shadowKernel[0][1], shadowKernel[0][0], fractionalCoord.y );
				shadowValues.y = mix( shadowKernel[0][2], shadowKernel[0][1], fractionalCoord.y );
				shadowValues.z = mix( shadowKernel[1][1], shadowKernel[1][0], fractionalCoord.y );
				shadowValues.w = mix( shadowKernel[1][2], shadowKernel[1][1], fractionalCoord.y );

				shadow = dot( shadowValues, vec4( 1.0 ) );

				shadowColor = shadowColor * vec3( ( 1.0 - shadowDarkness[ i ] * shadow ) );

			#else

				vec4 rgbaDepth = texture2D( shadowMap[ i ], shadowCoord.xy );
				float fDepth = unpackDepth( rgbaDepth );

				if ( fDepth < shadowCoord.z )

		// spot with multiple shadows is darker

					shadowColor = shadowColor * vec3( 1.0 - shadowDarkness[ i ] );

		// spot with multiple shadows has the same color as single shadow spot

		// 					shadowColor = min( shadowColor, vec3( shadowDarkness[ i ] ) );

			#endif

		}


		#ifdef SHADOWMAP_DEBUG

			#ifdef SHADOWMAP_CASCADE

				if ( inFrustum && inFrustumCount == 1 ) outgoingLight *= frustumColors[ i ];

			#else

				if ( inFrustum ) outgoingLight *= frustumColors[ i ];

			#endif

		#endif

	}

	// NOTE: I am unsure if this is correct in linear space.  -bhouston, Dec 29, 2014
	shadowColor = inputToLinear( shadowColor );

	outgoingLight = outgoingLight * shadowColor;

#endif


	outgoingLight = linearToOutput( outgoingLight );

#ifdef USE_FOG

	#ifdef USE_LOGDEPTHBUF_EXT

		float depth = gl_FragDepthEXT / gl_FragCoord.w;

	#else

		float depth = gl_FragCoord.z / gl_FragCoord.w;

	#endif

	#ifdef FOG_EXP2

		float fogFactor = exp2( - square( fogDensity ) * square( depth ) * LOG2 );
		fogFactor = whiteCompliment( fogFactor );

	#else

		float fogFactor = smoothstep( fogNear, fogFar, depth );

	#endif
	
	outgoingLight = mix( outgoingLight, fogColor, fogFactor );

#endif
  fragColor = vec4( outgoingLight, diffuseColor.a );
}