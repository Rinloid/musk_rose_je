#if !defined COMPOSITE3_GLSL_INCLUDED
#define COMPOSITE3_GLSL_INCLUDED

#if defined COMPOSITE3_FSH
#	extension GL_ARB_explicit_attrib_location : enable
	const bool colortex8MipmapEnabled = true;

	uniform sampler2D colortex0, colortex3, colortex8;

	in vec2 uv;

	#include "/utils/musk_rose_bloom.glsl"

	/* DRAWBUFFERS:08 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;

	void main() {
	vec4 translucent = texture(colortex3, uv);
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = getPreBloomBlur(colortex8, uv);
	bloom *= mix(vec3(1.0, 1.0, 1.0), translucent.rgb, translucent.a);
	bloom += albedo * 0.05;

	bloom = clamp(bloom * 5.0, 0.0, 1.0);

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex8 */
		fragData1 = vec4(bloom, texture(colortex8, uv).a);
	}
#endif /* defined COMPOSITE3_FSH */

#if defined COMPOSITE3_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE3_VSH */

#endif /* !defined COMPOSITE3_GLSL_INCLUDED */