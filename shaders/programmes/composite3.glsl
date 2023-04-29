#if !defined COMPOSITE3_GLSL_INCLUDED
#define COMPOSITE3_GLSL_INCLUDED

#if defined COMPOSITE3_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0;
	uniform sampler2D colortex6;
	uniform sampler2D depthtex2;
	uniform float viewWidth, viewHeight;

	in vec2 uv;

	/* DRAWBUFFERS:0 */
	layout(location = 0) out vec4 fragData0;

	#define ENABLE_BLUR BLUR_VERTICAL
	#include "/utils/musk_rose_blur.glsl"

	vec3 textureDistorted(const sampler2D tex, const vec2 uv, const vec2 direction, const vec3 distortion) {
	return vec3(
		texture(tex, uv + direction * distortion.r).r,
		texture(tex, uv + direction * distortion.g).g,
		texture(tex, uv + direction * distortion.b).b
	);
	}

	const int ghosts = 4;
	const float ghostDispersal = 0.8;
	const float haloWidth = 0.2;
	const float lensDistortion = 20.0;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	float depth = texture(depthtex2, uv).r;
	vec2 screenResolution = vec2(viewWidth, viewHeight);

	#ifdef ENABLE_LENSFLARE
		vec2 texcoord = -uv + vec2(1.0);
		vec2 ghostVec = (vec2(0.5) - texcoord) * ghostDispersal;

		vec2 texelSize = 1.0 / screenResolution;
		vec3 distortion = vec3(-texelSize.x * lensDistortion, 0.0, texelSize.x * lensDistortion);
		vec2 direction = normalize(ghostVec);

		vec3 lensFlare = vec3(0.0);
		for (int i = 0; i < ghosts; ++i) { 
			vec2 offset = fract(texcoord + ghostVec * float(i));

			vec2 haloVec = normalize(ghostVec) * haloWidth;
			float weight = length(vec2(0.5) - fract(texcoord + haloVec)) / length(vec2(0.5));
			weight = pow(1.0 - weight, 10.0) * 0.5;

			lensFlare += textureDistorted(colortex6, offset + haloVec * 0.08, direction, distortion).rgb * weight;
		}

		albedo += lensFlare;
	#endif

		fragData0 = vec4(albedo, 1.0);
	}
#endif /* defined COMPOSITE3_FSH */

#if defined COMPOSITE3_VSH
	uniform mat4 modelViewMatrix;
	uniform mat4 projectionMatrix;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;
		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE3_VSH */

#endif /* !defined COMPOSITE3_GLSL_INCLUDED */