#if !defined COMPOSITE5_GLSL_INCLUDED
#define COMPOSITE5_GLSL_INCLUDED

#if defined COMPOSITE5_FSH
#	extension GL_ARB_explicit_attrib_location : enable
	const bool colortex8MipmapEnabled = true;

	uniform sampler2D colortex0, colortex6, colortex8;
	uniform sampler2D depthtex0, depthtex1, depthtex2;
	uniform float viewWidth, viewHeight;

	in vec2 uv;

	#define ENABLE_BLUR BLUR_HORIZONTAL
	#include "/utils/musk_rose_bloom.glsl"

	/* DRAWBUFFERS:0 */
	layout(location = 0) out vec4 fragData0;

	vec3 hdrExposure(const vec3 col, const float over, const float under) {
		return mix(col / over, col * under, col);
	}

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = vec3(0.0, 0.0, 0.0);

	float emissive = texture(colortex6, uv).g;

	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

	bloom = getBloomBlur(colortex8, uv) * 0.65;

	albedo *= 1.0 - bloom;
	albedo += bloom;

	albedo /= albedo + 1.0;
	albedo = hdrExposure(albedo, 1.0, 2.6);

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

	}
#endif /* defined COMPOSITE5_FSH */

#if defined COMPOSITE5_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE5_VSH */

#endif /* !defined COMPOSITE5_GLSL_INCLUDED */