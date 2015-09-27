#ifdef USE_ALPHAMAP

	diffuseColor.a *= texture( alphaMap, vUv ).g;

#endif
