#include "../programmes/musk_rose_config.glsl"

#if !defined COMPOSITE1_GLSL_INCLUDED
#define COMPOSITE1_GLSL_INCLUDED

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_composite.glsl"

#if defined COMPOSITE1_FSH
#extension GL_ARB_explicit_attrib_location : enable

in vec2 uv;
in vec3 sunPos;
in vec3 moonPos;
in vec3 shadowLightPos;

#include "../programmes/utils/musk_rose_dither.glsl"
#include "../programmes/musk_rose_position.glsl"
#include "../programmes/musk_rose_sky.glsl"
#include "../programmes/utils/musk_rose_pbr.glsl"

/*
 ** Based on one by sad (@bamb0san)
 ** https://github.com/bambosan/Water-Only-Shaders
*/
vec3 getRayTracePosHit(const vec3 viewPos, const vec3 refPos) {
	const int raySteps = 200;

	vec3 result = vec3(0.0, 0.0, 0.0);

	vec3 rayOrig = getScreenPos(viewPos).xyz;
	vec3 rayDir  = getScreenPos(viewPos + refPos).xyz;
	rayDir = normalize(rayDir - rayOrig) / float(raySteps);

	float prevDepth = texture(depthtex0, rayOrig.xy).r;
	for (int i = 0; i < raySteps && refPos.z < 0.0 && rayOrig.x > 0.0 && rayOrig.y > 0.0 && rayOrig.x < 1.0 && rayOrig.y < 1.0; i++) {
		float currDepth = texture(depthtex0, rayOrig.xy).r;
		if (rayOrig.z > currDepth && prevDepth < currDepth) {
			result = vec3(rayOrig.xy, 1.0);
			break;
		}
		
		rayOrig += rayDir;
	}
	
	return result;
}

/* DRAWBUFFERS:0369 */
layout(location = 0) out vec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;
layout(location = 3) out vec4 fragData3;

void main() {
vec4 translucent = texture(colortex3, uv);
vec3 albedo = texture(colortex0, uv).rgb;
vec3 bloom = texture(colortex9, uv).rgb;
vec3 fNormal = texture(colortex2, uv).rgb * 2.0 - 1.0;
vec2 uv1 = texture(colortex4, uv).rg;
float vanillaAO = texture(colortex4, uv).b;
float roughness = texture(colortex5, uv).r;
float emissive = texture(colortex5, uv).g;
float reflectance = texture(colortex5, uv).b;

vec3 F0 = mix(vec3(0.04, 0.04, 0.04), albedo, reflectance);

vec3 viewPos0 = getViewPos(depthtex0, uv).xyz;
vec3 viewPos1 = getViewPos(depthtex1, uv).xyz;

vec3 relPos0 = getRelPos(depthtex0, uv).xyz;
vec3 relPos1 = getRelPos(depthtex1, uv).xyz;

vec3 fragPos0 = relPos0 + cameraPosition;
vec3 fragPos1 = relPos1 + cameraPosition;

vec3 pos0 = normalize(relPos0);
vec3 pos1 = normalize(relPos1);

vec3 viewDir0 = -pos0;
vec3 viewDir1 = -pos1;

vec3 reflection = albedo;

if (texture(depthtex0, uv).r != 1.0) {
vec3 refPos = reflect(normalize(viewPos0), mat3(gbufferModelView) * fNormal);
vec3 refUV = getScreenPos(refPos).xyz;

if (uv1.y > 0.6) {
	vec2 atmoUV = vec2(shadowLightPos.y, viewDir0.y) * 0.5 + 0.5;
	vec3 skyReflection = fogColor.rgb;

	reflection = mix(reflection, skyReflection, smoothstep(0.6, 1.0, uv1.y));
}

#ifdef ENABLE_SSR
	#ifdef SSR_RAYTRACING
		if (getRayTracePosHit(viewPos0, refPos).z > 0.5) {
			reflection = texture(colortex0, getRayTracePosHit(viewPos0, refPos).xy).rgb;
			bloom += texture(colortex9, getRayTracePosHit(viewPos0, refPos).xy).rgb * texture(colortex5, getRayTracePosHit(viewPos0, refPos).xy).g * F0;
		}
	#else
		if (!(refUV.x < 0.0 || refUV.x > 1.0 || refUV.y < 0.0 || refUV.y > 1.0 || refUV.z < 0.0 || refUV.z > 1.0)) {
			reflection = texture(colortex0, refUV.xy).rgb;
			bloom += texture(colortex9, refUV.xy).rgb * texture(colortex5, refUV.xy).g * F0;
		}
	#endif
#endif
}

	/* colortex0 (gcolor) */
	fragData0 = vec4(albedo, 1.0);

	/* colortex3 (composite) */
	fragData1 = translucent;

	/* colortex6 (gaux3) */
	fragData2 = vec4(reflection, 1.0);

	/* colortex9 */
	fragData3 = vec4(bloom, 1.0);

} /* main */
#endif /* defined COMPOSITE1_FSH */

#if defined COMPOSITE1_VSH
#include "../programmes/attributes/attribute_for_all.glsl"

out vec2 uv;
out vec3 sunPos;
out vec3 moonPos;
out vec3 shadowLightPos;

void main() {
uv = vaUV0;

sunPos = normalize(mat3(gbufferModelViewInverse) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * moonPosition);
shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

	gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
} /* main */
#endif /* defined COMPOSITE1_VSH */

#endif /* !defined COMPOSITE1_GLSL_INCLUDED */