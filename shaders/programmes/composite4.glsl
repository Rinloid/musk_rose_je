#if !defined COMPOSITE4_GLSL_INCLUDED
#define COMPOSITE4_GLSL_INCLUDED

#if defined COMPOSITE4_FSH
#	extension GL_ARB_explicit_attrib_location : enable
	const bool colortex8MipmapEnabled = true;

	uniform sampler2D colortex0, colortex8;
	uniform sampler2D depthtex0, depthtex1, depthtex2;
	uniform float viewWidth, viewHeight;

	in vec2 uv;

	#define ENABLE_BLUR BLUR_VERTICAL
	#include "/utils/musk_rose_bloom.glsl"

	/* DRAWBUFFERS:08 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = vec3(0.0, 0.0, 0.0);

	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

	bloom = getBloomBlur(colortex8, uv);

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex8 */
		fragData1 = vec4(bloom, texture(colortex8, uv).a);
	}
#endif /* defined COMPOSITE4_FSH */

#if defined COMPOSITE4_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE4_VSH */

#endif /* !defined COMPOSITE4_GLSL_INCLUDED */