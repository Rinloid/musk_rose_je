#if !defined DEFERRED_GLSL_INCLUDED
#define DEFERRED_GLSL_INCLUDED

#if defined DEFERRED_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0;
	uniform sampler2D colortex5;
	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 cameraPosition;
	uniform vec3 skyColor, fogColor;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform int moonPhase;

	in vec2 uv;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

	vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
		vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

		return viewPos / viewPos.w;
	}

	vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
		vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
		
		return relPos / relPos.w;
	}

	#include "/utils/musk_rose_config.glsl"
	#include "/utils/musk_rose_sky.glsl"

#	define CLOUDS_REFLECTION 1

	/* DRAWBUFFERS:056 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = texture(colortex5, uv).rgb;
	vec3 lensflare = vec3(0.0);
	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;

	vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth0).xyz;
	vec3 relPos  = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0).xyz;
	vec3 fragPos = relPos + cameraPosition;

	if (depth0 == 1.0) {
		#ifdef ENABLE_SHADER_SKY
			vec3 cloudPos = mat3(gbufferModelViewInverse) * viewPos.xyz / length(viewPos.xyz);
			albedo = getSky(normalize(relPos), cloudPos, cameraPosition, shadowLightPos, vec3(0.4, 0.65, 1.0), skyColor, fogColor, max(0.0, sin(sunPos.y)), rainStrength, frameTimeCounter, moonPhase);
			bloom += vec3(getSunPoint(normalize(relPos), sunPos, rainStrength));
			lensflare += vec3(getSunPoint(normalize(relPos), sunPos, rainStrength));
		#endif
	}

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex5 (gaux2) */
		fragData1 = vec4(bloom, 1.0);

		/* colortex6 (gaux3) */
		fragData2 = vec4(lensflare, 1.0);
	}
#endif /* defined DEFERRED_FSH */

#if defined DEFERRED_VSH
	uniform mat4 modelViewMatrix;
	uniform mat4 projectionMatrix;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 sunPosition, moonPosition, shadowLightPosition;

	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;
	out vec3 sunPos;
	out vec3 moonPos;
	out vec3 shadowLightPos;

	void main() {
	uv = vaUV0;
	sunPos         = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	moonPos        = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined DEFERRED_VSH */

#endif /* !defined DEFERRED_GLSL_INCLUDED */