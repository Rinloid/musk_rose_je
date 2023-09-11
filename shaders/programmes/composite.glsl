#if !defined COMPOSITE_GLSL_INCLUDED
#define COMPOSITE_GLSL_INCLUDED

#if defined COMPOSITE_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0, colortex1, colortex2, colortex3, colortex6, colortex7;
	uniform sampler2D depthtex0, depthtex1;
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;
	uniform sampler2D shadowcolor0;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection, shadowModelView;
	uniform float far, near;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform int isEyeInWater;

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

	#include "/utils/musk_rose_shadow.glsl"

	vec4 getShadowPos(const mat4 shadowModelView, const mat4 shadowProj, const vec3 relPos, const float diffuse) {
		const float shadowBias = 0.03;

		vec4 shadowPos = vec4(relPos, 1.0);
		shadowPos = shadowProj * (shadowModelView * shadowPos);

		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor);
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		
		shadowPos.z -= shadowBias * (distortFactor * distortFactor) / abs(diffuse);

		return shadowPos;
	}

	float getFog(const int fogMode, const float fogStart, const float fogEnd, const vec3 pos) {
		if (fogMode == 9729) { // GL_LINEAR
			return clamp((length(pos) - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
		} else if (fogMode == 2048) { // GL_EXP
			return 1.0 - clamp(1.0 / exp(max(0.0, length(pos) - fogStart) * log(1.0 / 0.03) / (fogEnd - fogStart)), 0.0, 1.0);
		} else if (fogMode == 2049) { // GL_EXP2
			float base = max(0.0, length(pos) - fogStart) * sqrt(log(1.0 / 0.015)) / (fogEnd - fogStart);
			return 1.0 - clamp(1.0 / exp(base * base), 0.0, 1.0);
		} else {
			return 0.0;
		}
	}

	#include "/utils/musk_rose_sky.glsl"
	#include "/utils/musk_rose_light.glsl"

	/* DRAWBUFFERS:013 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec4 translucent = texture(colortex3, uv);

	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;

	vec3 normal = texture(colortex2, uv).rgb * 2.0 - 1.0;
	float roughness = texture(colortex6, uv).r;
	float emissive = texture(colortex6, uv).g;
	float F0 = texture(colortex6, uv).b;

	float mcEntity = int(texture(colortex7, uv).r * 10.0 + 0.1);

	vec3 viewPos0 = getViewPos(gbufferProjectionInverse, uv, depth0).xyz;
	vec3 viewPos1 = getViewPos(gbufferProjectionInverse, uv, depth1).xyz;
	vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0).xyz;
	vec3 pos = normalize(relPos);
	vec3 viewDir = -pos;

	bool isUnderwater = isEyeInWater == 0 ? int(mcEntity) == 1 : isEyeInWater == 1 ? true : false;

	vec4 totalFogRay = vec4(0.0, 0.0, 0.0, 0.0);

	vec2 atmoUV = (vec2(shadowLightPos.y, viewDir.y) * mix(0.85, 1.0, bayerX64(gl_FragCoord.xy)) * 0.5 + 0.5);

	vec4 fogCol = vec4(0.0, 0.0, 0.0, 0.0);
	fogCol.rgb = getSkylightCol(colortex13, colortex12, pos, sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75);
	fogCol.a = depth0 != 1 ? getFog(2049, 0.0, isEyeInWater == 1 ? 0.2 : 1.0, (isEyeInWater == 1 ? viewPos1 - viewPos0 : viewPos0) / far) : 0.0;
	
	vec4 underwaterFogCol = vec4(0.0, 0.0, 0.0, 0.0);
	if (isUnderwater) {
		vec3 waterAbsorb = getSkylightCol(colortex13, colortex12, pos, sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75) * 0.5;
		vec3 waterScatter = vec3(0.002, 0.015, 0.02) * (1.0 - waterAbsorb);
		underwaterFogCol.rgb = waterAbsorb + waterScatter;
		underwaterFogCol.a = getFog(2049, 0.0, 0.2, (isEyeInWater == 1 ? viewPos0 : viewPos1 - viewPos0) / far);
	}


	totalFogRay.rgb = mix(mix(totalFogRay.rgb, underwaterFogCol.rgb, underwaterFogCol.a), isEyeInWater == 1 ? underwaterFogCol.rgb : fogCol.rgb, fogCol.a);
	totalFogRay.a = min(underwaterFogCol.a + fogCol.a, 1.0);

	vec4 rayPos = getShadowPos(shadowModelView, shadowProjection, relPos, 1.0);
	vec3 rayOrig = relPos;
    vec4 rayShadowCol = vec4(0.0, 0.0, 0.0, 0.0);
	float rayFactor = 0.0;
	
	int raySteps = 32;
	rayOrig *= bayerX64(gl_FragCoord.xy) * 0.5 + 0.5;
	for (int i = 0; i < raySteps; i++) {
		rayOrig.xyz *= 0.75;
		vec4 rayPos = getShadowPos(shadowModelView, shadowProjection, rayOrig, 1.0);
		if (texture(shadowtex1, rayPos.xy).r > rayPos.z) {
			rayFactor += rayPos.w;
			if (texture(shadowtex0, rayPos.xy).r < rayPos.z) {
				rayShadowCol += texture(shadowcolor0, rayPos.xy);
				rayFactor += texture(shadowcolor0, rayPos.xy).a;
			}
		}
	} rayFactor /= float(raySteps);
	  rayShadowCol /= float(raySteps);
	rayFactor = min(rayFactor * max(0.0, 1.0 - distance(normalize(relPos), shadowLightPos)) * smoothstep(0.0, 0.1, sin(sunPos.y)), 1.0) * (1.0 - rainStrength);

	vec3 totalRayCol = isEyeInWater == 1 ? underwaterFogCol.rgb : fogCol.rgb;
	totalRayCol = brighten(mix(totalRayCol, brighten(rayShadowCol.rgb), rayShadowCol.a));

	totalFogRay = vec4(mix(totalFogRay.rgb, totalRayCol, rayFactor), min(totalFogRay.a + rayFactor, 1.0));
	albedo = mix(albedo, totalFogRay.rgb, totalFogRay.a);
	translucent.rgb = mix(translucent.rgb, totalFogRay.rgb, totalFogRay.a);


		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex1 (gdepth) */
		fragData1 = totalFogRay;

		/* colortex3 (composite) */
		fragData2 = translucent;
	}
#endif /* defined COMPOSITE_FSH */

#if defined COMPOSITE_VSH
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
#endif /* defined COMPOSITE_VSH */

#endif /* !defined COMPOSITE_GLSL_INCLUDED */