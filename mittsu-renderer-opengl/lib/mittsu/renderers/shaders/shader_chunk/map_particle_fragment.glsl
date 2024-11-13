#ifdef USE_MAP

	diffuseColor *= texture( map, vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y ) * offsetRepeat.zw + offsetRepeat.xy );

#endif
