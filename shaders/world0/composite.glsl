#include "../programmes/musk_rose_config.glsl"

#if !defined COMPOSITE_GLSL_INCLUDED
#define COMPOSITE_GLSL_INCLUDED

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_composite.glsl"

#if defined COMPOSITE_FSH
#extension GL_ARB_explicit_attrib_location : enable

in vec2 uv;
in vec3 sunPos;
in vec3 moonPos;
in vec3 shadowLightPos;

#include "../programmes/utils/musk_rose_dither.glsl"
#include "../programmes/utils/musk_rose_filter.glsl"
#include "../programmes/utils/musk_rose_ssao.glsl"
#include "../programmes/musk_rose_position.glsl"
#include "../programmes/musk_rose_lights.glsl"

/* DRAWBUFFERS:0379 */
layout(location = 0) out vec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;
layout(location = 3) out vec4 fragData3;

void main() {
vec4 translucent = texture(colortex3, uv);
vec3 reflectedLight = texture(colortex7, uv).rgb;
vec3 albedo = texture(colortex0, uv).rgb;
vec3 bloom = texture(colortex9, uv).rgb;
vec3 fNormal = texture(colortex2, uv).rgb * 2.0 - 1.0;
vec2 uv1 = texture(colortex4, uv).rg;
float vanillaAO = texture(colortex4, uv).b;
float roughness = texture(colortex5, uv).r;
float emissive = texture(colortex5, uv).g;
float reflectance = texture(colortex5, uv).b;

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

vec3 totalLight = vec3(0.0, 0.0, 0.0);

if (translucent.a > 0.0) {
float totalAO = clamp(vanillaAO * AO_VANILLA_INTENSITY + getSSAO(depthtex0, viewPos1, uv) * AO_SHADER_INTENSITY, 0.0, 1.0);
float diffuse = max(0.0, dot(shadowLightPos, fNormal));

vec4 shadowPos = getShadowPos(getRelPos(depthtex0, uv), diffuse);
vec4 shadows = vec4(0.0, 0.0, 0.0, 0.0);
if (shadowPos.w > 0.0) {
	for (int i = 0; i < int(shadowSamples.length()); i++) {
		vec2 offset = shadowSamples[i] / float(shadowMapResolution);
		offset += bayerX64(gl_FragCoord.xy) / float(shadowMapResolution);
		
		if (texture(shadowtex1, shadowPos.xy + offset).r < shadowPos.z) {
			shadows += vec4(0.0, 0.0, 0.0, 1.0);
		} else if (texture(shadowtex0, shadowPos.xy + offset).r < shadowPos.z) {
			shadows += texture(shadowcolor0, shadowPos.xy + offset);
		}
	} shadows /= shadowSamples.length();
}

shadows.a = 1.0 - mix(0.0, 1.0 - shadows.a, diffuse);

vec3 directionalLight = vec3(0.0, 0.0, 0.0);
vec3 undirectionalLight = vec3(0.0, 0.0, 0.0);

vec3 ambientLight = getAmbientLight(sunPos, uv1, totalAO).rgb * getAmbientLight(sunPos, uv1, totalAO).a;
vec3 skylight = getSkylight(sunPos, uv1).rgb * getSkylight(sunPos, uv1).a;
vec3 sunlight = getSunlight(shadows, sunPos).rgb * getSunlight(shadows, sunPos).a;
vec3 moonlight = getMoonlight(shadows, moonPos).rgb * getMoonlight(shadows, moonPos).a;
vec3 pointlight = getPointlight(uv1).rgb * getPointlight(uv1).a;

undirectionalLight += ambientLight;
undirectionalLight += skylight;
directionalLight += sunlight;
directionalLight += moonlight;
undirectionalLight += pointlight;

totalLight = undirectionalLight + directionalLight;

vec3 directionalLightRatio = directionalLight / max(vec3(0.001), totalLight);

totalLight = uncharted2Tonemap(totalLight, 128.0, 1.2);
totalLight = hdrExposure(totalLight, 128.0, EXPOSURE);

translucent.rgb *= totalLight;

reflectedLight = directionalLightRatio;
}

	/* colortex0 (gcolor) */
	fragData0 = vec4(albedo, 1.0);

	/* colortex3 (composite) */
	fragData1 = translucent;

	/* colortex7 (gaux4) */
	fragData2 = vec4(reflectedLight, 1.0);

	/* colortex9 */
	fragData3 = vec4(bloom, 1.0);

} /* main */
#endif /* defined COMPOSITE_FSH */

#if defined COMPOSITE_VSH
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
#endif /* defined COMPOSITE_VSH */

#endif /* !defined COMPOSITE_GLSL_INCLUDED */