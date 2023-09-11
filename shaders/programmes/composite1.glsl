#if !defined COMPOSITE1_GLSL_INCLUDED
#define COMPOSITE1_GLSL_INCLUDED

#if defined COMPOSITE1_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0, colortex1, colortex2, colortex6, colortex7, colortex8;
	uniform sampler2D depthtex0, depthtex1;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 skyColor, fogColor;
	uniform float frameTimeCounter;
	uniform float rainStrength;

	in vec2 uv;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

	float bayerX2(vec2 a) {
		return fract(dot(floor(a), vec2(0.5, floor(a).y * 0.75)));
	}

	#define bayerX4(a)  (bayerX2 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX8(a)  (bayerX4 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX16(a) (bayerX8 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX32(a) (bayerX16(0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX64(a) (bayerX32(0.5 * (a)) * 0.25 + bayerX2(a))

	vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
		vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

		return viewPos / viewPos.w;
	}

	vec3 getScreenPos(const mat4 proj, const vec3 pos) {
		vec4 viewPos = proj * vec4(pos, 1.0);

		return (viewPos.xyz / viewPos.w) * 0.5 + 0.5;
	}

	vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
		vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
		
		return relPos / relPos.w;
	}

	#include "/utils/musk_rose_config.glsl"

	/*
	 ** Based on one by sad (@bamb0san)
	 ** https://github.com/bambosan/Water-Only-Shaders
	*/
	vec3 getRayTracePosHit(sampler2D depthTex, const mat4 proj, const vec3 viewPos, const vec3 refPos) {
		const int raySteps = 200;

		vec3 result = vec3(0.0);

		vec3 rayOrig = getScreenPos(proj, viewPos);
		vec3 rayDir  = getScreenPos(proj, viewPos + refPos);
		rayDir = normalize(rayDir - rayOrig) / float(raySteps);

		float prevDepth = texture(depthTex, rayOrig.xy).r;
		for (int i = 0; i < raySteps && refPos.z < 0.0 && rayOrig.x > 0.0 && rayOrig.y > 0.0 && rayOrig.x < 1.0 && rayOrig.y < 1.0; i++) {
			float currDepth = texture(depthTex, rayOrig.xy).r;
			if (rayOrig.z > currDepth && prevDepth < currDepth) {
				result = vec3(rayOrig.xy, 1.0);
				break;
			}
			
			rayOrig += rayDir;
		}
		
		return result;
	}

	#define CLOUDS_QUALITY_LOW
	#include "/utils/musk_rose_sky.glsl"

	/* DRAWBUFFERS:048 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 normal = texture(colortex2, uv).rgb * 2.0 - 1.0;

	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;

	float F0 = texture(colortex6, uv).b;
	vec3 bloom = texture(colortex8, uv).rgb;
	
	vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth0).xyz;
	vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0).xyz;
	vec3 pos = normalize(relPos);
	vec3 viewDir = -pos;
	float outdoor = texture(colortex7, uv).b;

	vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * normal);
	vec3 refUV = getScreenPos(gbufferProjection, refPos);
	vec2 atmoUV = (vec2(shadowLightPos.y, viewDir.y) * mix(0.85, 1.0, bayerX64(gl_FragCoord.xy)) * 0.5 + 0.5);

	vec3 reflection = getSky(colortex13, colortex12, reflect(pos, normal), sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75);
	reflection = mix(albedo, reflection, outdoor);

	#define ENABLE_SSR
	#define SSR_RAYTRACING

	#ifdef ENABLE_SSR
		#ifdef SSR_RAYTRACING
			if (getRayTracePosHit(depthtex0, gbufferProjection, viewPos, refPos).z > 0.5) {
				reflection = texture(colortex0, getRayTracePosHit(depthtex0, gbufferProjection, viewPos, refPos).xy).rgb;
				bloom += texture(colortex8, getRayTracePosHit(depthtex0, gbufferProjection, viewPos, refPos).xy).rgb * F0;
			}
		#else
			if (!(refUV.x < 0 || refUV.x > 1 || refUV.y < 0 || refUV.y > 1 || refUV.z < 0 || refUV.z > 1.0)) {
				reflection = texture(colortex0, refUV.xy).rgb;
				bloom += texture(colortex8, refUV.xy).rgb * F0;
			}
		#endif
	#endif

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex4 (gaux1) */
		fragData1 = vec4(reflection, 1.0);

		/* colortex8 */
		fragData2 = vec4(bloom, texture(colortex8, uv).a);
	}
#endif /* defined COMPOSITE1_FSH */

#if defined COMPOSITE1_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;
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
#endif /* defined COMPOSITE1_VSH */

#endif /* !defined COMPOSITE1_GLSL_INCLUDED */