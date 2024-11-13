#ifdef USE_LOGDEPTHBUF

	uniform float logDepthBufFC;

	#ifdef USE_LOGDEPTHBUF_EXT

		#extension GL_EXT_frag_depth : enable
		in float vFragDepth;

	#endif

#endif