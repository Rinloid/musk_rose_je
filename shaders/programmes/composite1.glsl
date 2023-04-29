#if !defined COMPOSITE1_GLSL_INCLUDED
#define COMPOSITE1_GLSL_INCLUDED

#if defined COMPOSITE1_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0;
	uniform sampler2D colortex5;
	uniform sampler2D depthtex2;
	uniform float viewWidth, viewHeight;
	uniform float centerDepthSmooth;

	in vec2 uv;

	/* DRAWBUFFERS:05 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;

	#define ENABLE_BLUR BLUR_HORIZONTAL
	#include "/utils/musk_rose_blur.glsl"

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = texture(colortex5, uv).rgb;
	float depth = texture(depthtex2, uv).r;
	float centreDepth = centerDepthSmooth;
	vec2 pixelSize = 1.0 / vec2(viewWidth, viewHeight);

	float unfocused = smoothstep(0.0, 0.025, abs(depth - centreDepth));

	int blurSteps = 12;
	float blurStrength = 1.0;

	bloom = vec3(0.0);
	
	bloom += getBlur(colortex5, uv, pixelSize, blurSteps, blurStrength);

		fragData0 = vec4(albedo, 1.0);
		fragData1 = vec4(bloom, 1.0);
	}
#endif /* defined COMPOSITE1_FSH */

#if defined COMPOSITE1_VSH
	uniform mat4 modelViewMatrix;
	uniform mat4 projectionMatrix;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;
		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE1_VSH */

#endif /* !defined COMPOSITE1_GLSL_INCLUDED */