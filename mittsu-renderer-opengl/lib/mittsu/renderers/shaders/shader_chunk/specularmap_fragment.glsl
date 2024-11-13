float specularStrength;

#ifdef USE_SPECULARMAP

	vec4 texelSpecular = texture( specularMap, vUv );
	specularStrength = texelSpecular.r;

#else

	specularStrength = 1.0;

#endif