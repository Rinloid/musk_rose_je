#if !defined COMPOSITE_GLSL_INCLUDED
#define COMPOSITE_GLSL_INCLUDED

#if defined COMPOSITE_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D specular;
	uniform sampler2D colortex0;
	uniform sampler2D colortex2;
	uniform sampler2D colortex3;
	uniform sampler2D colortex4;
	uniform sampler2D colortex5;
	uniform sampler2D colortex6;
	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;
	uniform sampler2D shadowcolor0;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection, shadowModelView;
	uniform vec3 cameraPosition;
	uniform vec3 skyColor, fogColor;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float near, far;
	uniform float viewWidth, viewHeight;
	uniform int isEyeInWater;
	uniform int moonPhase;

	in vec2 uv;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

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
	#include "/utils/musk_rose_clouds.glsl"
	#include "/utils/musk_rose_water.glsl"
	#include "/utils/musk_rose_light.glsl"
	#include "/utils/musk_rose_fog.glsl"

	/*
	 ** Based on one by sad (@bamb0san)
	 ** https://github.com/bambosan/Water-Only-Shaders
	*/
	vec3 getRayTracePosHit(sampler2D depthTex, const mat4 proj, const vec3 viewPos, const vec3 refPos) {
		const int raySteps = 512;

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

	float fresnelSchlick(const vec3 H, const vec3 N, const float F0) {
		float cosTheta = clamp(1.0 - max(0.0, dot(H, N)), 0.0, 1.0);

		return F0 + (1.0 - F0) * cosTheta * cosTheta * cosTheta * cosTheta * cosTheta;
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

	/* DRAWBUFFERS:05 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 normal = texture(colortex2, uv).rgb * 2.0 - 1.0;
	vec4 translucent = texture(colortex3, uv);
	int mcEntity = int(texture(colortex6, uv).r * 10.0 + 0.1);
	float roughness = texture(colortex4, uv).b;
	float reflectance = texture(colortex4, uv).g;
	vec4 bloom = texture(colortex5, uv);
	float sunLevel = texture(colortex4, uv).r;
	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;
	bool underwater = isEyeInWater == 0 ? int(mcEntity) == 1 : isEyeInWater == 1 ? int(mcEntity) != 1 : false;

	vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth0).xyz;
	vec3 relPos  = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0).xyz;
	vec3 fragPos = relPos + cameraPosition;

	float daylight = max(0.0, sin(sunPos.y));

	vec3 rayShadowCol = vec3(0.0);
	vec3 totalrayCol = vec3(0.6, 0.47, 0.27);
	vec3 relPosRay = relPos;
	float rayFactor = 0.0;
	if (isEyeInWater == 0 && (1.0 - rainStrength) > 0.0) {
		relPosRay *= mix(1.0, 1.3, hash13(floor(relPosRay * 2048.0) + frameTimeCounter));
		while (dot(relPosRay.xyz, relPosRay.xyz) > 0.25 * 0.25) {
			relPosRay.xyz *= 0.75;
			vec4 rayPos = getShadowPos(shadowModelView, shadowProjection, relPosRay, 1.0);
			if (texture(shadowtex1, rayPos.xy).r > rayPos.z) {
				if (depth0 != 1.0) {
					rayFactor = mix(rayPos.w, rayFactor, exp2(length(relPosRay.xyz) * -0.0625));
				}
			}
		}
	}
	rayFactor = mix(0.0, rayFactor, sunLevel);
	
	float sunRayFactor = min(rayFactor * max(0.0, 1.0 - distance(normalize(relPos), shadowLightPos)) * smoothstep(0.0, 0.1, daylight), 1.0) * (1.0 - rainStrength);

	if (depth0 != 1.0) { // Is not sky
	vec3 refraction = albedo;
	if (mcEntity == 1) refraction = texture(colortex0, refract(vec3(uv, depth0), getWaterWaveNormal(getWaterParallax(viewPos, fragPos.xz, frameTimeCounter), frameTimeCounter) * 0.2, 1.0).xy).rgb;

	vec3 fogCol = vec3(0.0);
	float fogFactor = 0.0;

	if (underwater) {
		fogCol = vec3(0.0, 0.1, 0.15);
		vec3 underWaterFogPos = isEyeInWater == 0 ? viewPos - getViewPos(gbufferProjectionInverse, uv, depth1).xyz : viewPos;
		fogFactor = getFog(vec2(near, far * 0.08), underWaterFogPos);
		refraction = mix(refraction, fogCol, fogFactor);
	}

	albedo = mix(refraction, translucent.rgb, translucent.a);

	if (reflectance > 0.1) {
	vec3 cloudPos = mat3(gbufferModelViewInverse) * viewPos.xyz / length(viewPos.xyz);
	cloudPos += hash13(floor(cloudPos * 2048.0)) * 0.2 * roughness;
	vec3 reflection = getSky(reflect(normalize(relPos), normal) + hash13(floor(normalize(relPos) * 2048.0)) * 0.2 * roughness, reflect(cloudPos, normal), cameraPosition, shadowLightPos, vec3(0.4, 0.65, 1.0), skyColor, fogColor, daylight, 0.0, frameTimeCounter, moonPhase);
	reflection = mix(albedo, reflection, sunLevel);
	vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * normal);
	refPos += hash13(floor(refPos * 2048.0)) * 0.2 * roughness;
		if (getRayTracePosHit(depthtex0, gbufferProjection, viewPos, refPos).z > 0.5) {
			reflection = texture(colortex0, getRayTracePosHit(depthtex0, gbufferProjection, viewPos, refPos).xy).rgb;
		}
		if (mcEntity == 1) {
			albedo = mix(albedo, reflection, fresnelSchlick(normalize(-relPos), normal, mix(0.04, dot(albedo, vec3(0.22, 0.707, 0.071)), reflectance)));
		} else {
			albedo = mix(albedo, reflection * getEnvironmentBRDF(normalize(-relPos), normal, roughness, mix(vec3(0.04), albedo, reflectance)), reflectance);
		}
	}
	fogCol = getSkyLightCol(normalize(relPos), shadowLightPos, vec3(0.4, 0.65, 1.0), skyColor, fogColor, daylight, rainStrength);
	fogCol = mix(vec3(getLuma(fogCol)), fogCol, sunLevel);
	fogFactor = getFog(vec2(near, far), relPos);
	albedo = mix(albedo, fogCol, min(fogFactor + sunRayFactor, 1.0));
	bloom.rgb = mix(bloom.rgb, vec3(0.0), min(fogFactor + sunRayFactor, 1.0));
	} // Is not sky

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex5 (gaux2) */
		fragData1 = vec4(bloom.rgb, 1.0);
	}
#endif /* defined COMPOSITE_FSH */

#if defined COMPOSITE_VSH
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
#endif /* defined COMPOSITE_VSH */

#endif /* !defined COMPOSITE_GLSL_INCLUDED */