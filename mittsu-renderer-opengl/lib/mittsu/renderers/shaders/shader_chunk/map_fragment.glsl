#ifdef USE_MAP

	vec4 texelColor = texture( map, vUv );

	texelColor.xyz = inputToLinear( texelColor.xyz );

	diffuseColor *= texelColor;

#endif