#include "../programmes/musk_rose_config.glsl"

#if !defined COMPOSITE2_GLSL_INCLUDED
#define COMPOSITE2_GLSL_INCLUDED

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_composite.glsl"

#if defined COMPOSITE2_FSH
#define CLOUDS_QUALITY_LOW
#extension GL_ARB_explicit_attrib_location : enable
const bool colortex6MipmapEnabled = true;

in vec2 uv;
in vec3 sunPos;
in vec3 moonPos;
in vec3 shadowLightPos;

#include "../programmes/utils/musk_rose_dither.glsl"
#include "../programmes/utils/musk_rose_pbr.glsl"
#include "../programmes/utils/musk_rose_filter.glsl"
#include "../programmes/musk_rose_position.glsl"
#include "../programmes/musk_rose_sky.glsl"

float getFogify(float x, float width) {
	return width / (x * x + width);
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

/* DRAWBUFFERS:039 */
layout(location = 0) out vec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;

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
float mcEntity = int(texture(colortex8, uv).r * 10.0 + 0.1);

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

float brightness = eyeBrightnessSmooth.y / 240.0;

if (texture(depthtex0, uv).r != 1.0) {
	vec3 F0 = mix(vec3(0.04, 0.04, 0.04), translucent.a > 0.0 ? translucent.rgb : albedo, reflectance);

	vec3 reflectedImage = textureLod(colortex6, uv, REFLECTRION_BLUR_INTENSITY + roughness * ROUGHNESS_BLUR_INTENSITY).rgb;
	reflectedImage *= getEnvironmentBRDF(viewDir0, fNormal, roughness, F0);

	vec3 specular = getSpecular(viewDir0, shadowLightPos, fNormal, roughness, F0);

	vec3 reflectedLight = textureLod(colortex7, uv, REFLECTRION_BLUR_INTENSITY + roughness * ROUGHNESS_BLUR_INTENSITY).rgb;
	reflectedLight *= specular;
	reflectedLight = clamp(reflectedLight, 0.0, 1.0);
	
	bloom += reflectedLight;

		albedo *= 1.0 - reflectance;
		albedo += reflectedImage + reflectedLight;
	if (translucent.a > 0.0) {
		translucent.rgb *= 1.0 - reflectance;
		translucent.rgb += reflectedImage + reflectedLight;
		translucent.a = mix(mix(translucent.a, translucent.a * 4.0, getLuma(getFresnelSchlick(viewDir0, fNormal, F0))), 1.0, getLuma(reflectedLight));
	}

	float fogVisibility = exp2((fragPos0.y * (-1.0 / FOG_HEIGHT))) * FOG_DENSITY;
	float fogVisibilityUnderwater = FOG_DENSITY_UNDERWATER;

	vec3 fogPos = relPos0;
	vec3 underwaterfogPos = relPos1 - relPos0;
	vec3 fogCol = vec3(0.0, 0.0, 0.0);
	vec2 atmoUV = vec2(shadowLightPos.y, viewDir0.y) * 0.5 + 0.5;

	fogCol = getAtmosphere(colortex14, colortex13, pos0, sunPos, shadowLightPos, atmoUV);
	//fogCol *= brightness;

	vec3 waterAbsorb = fogCol * getLuma(WATER_COL);
	vec3 waterScatter = WATER_COL * (1.0 - waterAbsorb);
	vec3 underwaterfogCol = (waterAbsorb + waterScatter) * 0.75 * clamp(sin(sunPos.y) * (1.0 - rainStrength), 0.25, 1.0);
/*
	float miePhase = getMiePhase(pos0, shadowLightPos, 0.75);
	vec3 sunRayCol = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * miePhase * texture(colortex14, atmoUV).rgb;
	sunRayCol = clamp(1.0 - exp(-1.0 * sunRayCol), 0.0, 1.0);

	int raySteps = 32;
	vec4 rayOrig = getRelPos(depthtex0, uv);
	float rayFactor = 0.0;
	
	rayOrig.xyz *= bayerX64(gl_FragCoord.xy + frameTimeCounter) * 0.5 + 0.5;
	
	for (int i = 0; i < raySteps; i++) {
		rayOrig.xyz *= 0.75;
		vec4 rayPos = getShadowPos(rayOrig, 1.0);
		if (texture(shadowtex1, rayPos.xy).r > rayPos.z) {
			rayFactor += rayPos.w * (1.0 / float(raySteps) * 2.0);
		}
	}
	rayFactor = clamp(rayFactor, 0.0, 1.0);

	albedo = mix(albedo, sunRayCol, sunRayCol * rayFactor * (1.0 - rainStrength));
	if (translucent.a > 0.0) {
		translucent.rgb = mix(translucent.rgb, sunRayCol, sunRayCol * rayFactor);
	}
*/
	if (isEyeInWater == 1) {
		albedo = mix(albedo, underwaterfogCol, clamp(getFog(FOG_QUALITY, 0.0, FOG_DISTANCE_UNDERWATER, fogPos / far) * fogVisibilityUnderwater, 0.0, 1.0));
	}

	if (translucent.a > 0.0) {
		if (isEyeInWater == 0 && int(mcEntity) == 1) {
			albedo = mix(albedo, underwaterfogCol, clamp(getFog(FOG_QUALITY, 0.0, FOG_DISTANCE_UNDERWATER, underwaterfogPos / far) * fogVisibilityUnderwater, 0.0, 1.0));
		}
		if (isEyeInWater == 1) {
			translucent.rgb = mix(translucent.rgb, underwaterfogCol, clamp(getFog(FOG_QUALITY, 0.0, FOG_DISTANCE_UNDERWATER, fogPos / far) * fogVisibilityUnderwater, 0.0, 1.0));
		}
	}

	albedo = mix(albedo, fogCol, clamp(getFog(FOG_QUALITY, 0.0, FOG_DISTANCE, fogPos / far) * fogVisibility, 0.0, 1.0));
	if (translucent.a > 0.0) {
		translucent.rgb = mix(translucent.rgb, fogCol, clamp(getFog(FOG_QUALITY, 0.0, FOG_DISTANCE, fogPos / far) * fogVisibility, 0.0, 1.0));
	}

}

bloom += (albedo - bloom) * getLuma(albedo - bloom) * 0.1;

	/* colortex0 (gcolor) */
	fragData0 = vec4(albedo, 1.0);

	/* colortex3 (composite) */
	fragData1 = translucent;

	/* colortex9 */
	fragData2 = vec4(bloom, 1.0);

} /* main */
#endif /* defined COMPOSITE2_FSH */

#if defined COMPOSITE2_VSH
#include "../programmes/attributes/attribute_for_all.glsl"

out vec2 uv;
out vec3 sunPos;
out vec3 moonPos;
out vec3 shadowLightPos;

void main() {
uv = vaUV0;

sunPos         = normalize(vec3(0.0, 1.0, 1.0));
moonPos        = -sunPos;
shadowLightPos = normalize(vec3(0.0, 1.0, 1.0));

	gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
} /* main */
#endif /* defined COMPOSITE2_VSH */

#endif /* !defined COMPOSITE2_GLSL_INCLUDED */