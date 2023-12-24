#include "../programmes/musk_rose_config.glsl"

#if !defined COMPOSITE4_GLSL_INCLUDED
#define COMPOSITE4_GLSL_INCLUDED

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_composite.glsl"

#if defined COMPOSITE4_FSH
#extension GL_ARB_explicit_attrib_location : enable
const bool colortex9MipmapEnabled = true;

in vec2 uv;
in vec3 sunPos;
in vec3 moonPos;
in vec3 shadowLightPos;

#include "../programmes/utils/musk_rose_dither.glsl"
#include "../programmes/musk_rose_position.glsl"

#define ENABLE_BLUR BLUR_HORIZONTAL
#include "../programmes/utils/musk_rose_blur.glsl"

/* DRAWBUFFERS:039 */
layout(location = 0) out vec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;

void main() {
vec4 translucent = texture(colortex3, uv);
vec3 albedo = texture(colortex0, uv).rgb;
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

vec3 bloom = vec3(0.0, 0.0, 0.0);
#ifdef ENABLE_BLOOM
	bloom = getBlur(colortex9, uv, 0.0, 12, 2.0);
#endif

	/* colortex0 (gcolor) */
	fragData0 = vec4(albedo, 1.0);

	/* colortex3 (composite) */
	fragData1 = translucent;

	/* colortex9 */
	fragData2 = vec4(bloom, 1.0);

} /* main */
#endif /* defined COMPOSITE4_FSH */

#if defined COMPOSITE4_VSH
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
#endif /* defined COMPOSITE4_VSH */

#endif /* !defined COMPOSITE4_GLSL_INCLUDED */