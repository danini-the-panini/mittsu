#ifdef USE_LIGHTMAP

	outgoingLight *= diffuseColor.xyz * texture( lightMap, vUv2 ).xyz;

#endif