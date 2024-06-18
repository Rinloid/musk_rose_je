#include "../programmes/musk_rose_config.glsl"

#if !defined GBUFFERS_GLSL_INCLUDED
#define GBUFFERS_GLSL_INCLUDED 1

#if defined GBUFFERS_ARMOR_GLINT || defined GBUFFERS_BEACONBEAM || defined GBUFFERS_BLOCK || defined GBUFFERS_CLOUDS || defined GBUFFERS_ENTITIES || defined GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_SKYTEXTURED || defined GBUFFERS_SPIDEREYES || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#	define USE_TEXTURES 1
#endif

#if defined GBUFFERS_BASIC || defined GBUFFERS_BLOCK || defined GBUFFERS_ENTITIES || GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#   define USE_LIGHTMAP 1
#endif

#if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
#	define USE_CHUNK_OFFSET 1
#endif

#if defined GBUFFERS_BASIC || defined GBUFFERS_BEACONBEAM || defined GBUFFERS_BLOCK || defined GBUFFERS_CLOUDS || defined GBUFFERS_ENTITIES || defined GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_LINE || defined GBUFFERS_SPIDEREYES || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#	define USE_ALPHA_TEST 1
#endif

#if defined GBUFFERS_WATER || defined GBUFFERS_HAND_WATER
#	define GBUFFERS_TRANSLUCENT 1
#endif

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_gbuffers.glsl"

#if defined GBUFFERS_FSH
#extension GL_ARB_explicit_attrib_location : enable
#extension GL_ARB_shader_texture_lod : enable

in vec2 uv0;
in vec2 uv1;
in vec2 midUV;
in vec4 vUV0;
in vec4 vUV0AM;
in mat3 tbnMatrix;
in vec4 col;
in vec4 viewPos;
in vec4 worldPos;
in vec3 vNormal;
in vec3 sunPos;
in vec3 moonPos;
in vec3 shadowLightPos;
in float mcEntity;

#include "../programmes/utils/musk_rose_dither.glsl"
#include "../programmes/utils/musk_rose_filter.glsl"
#include "../programmes/utils/musk_rose_ssao.glsl"
#include "../programmes/utils/musk_rose_pom.glsl"
#include "../programmes/musk_rose_position.glsl"
#include "../programmes/musk_rose_water.glsl"
#include "../programmes/musk_rose_rain.glsl"

mat3 getTBNMatrix(const vec3 normal) {
    vec3 T = vec3(abs(normal.y) + normal.z, 0.0, normal.x);
    vec3 B = vec3(0.0, -abs(normal).x - abs(normal).z, abs(normal).y);
    vec3 N = normal;

    return transpose(mat3(T, B, N));
}

/* DRAWBUFFERS:01234589 */
layout(location = 0) out vec4 fragData0;
layout(location = 1) out vec4 fragData1;
layout(location = 2) out vec4 fragData2;
layout(location = 3) out vec4 fragData3;
layout(location = 4) out vec4 fragData4;
layout(location = 5) out vec4 fragData5;
layout(location = 6) out vec4 fragData6;
layout(location = 7) out vec4 fragData7;

void main() {
float isLine = 1.0;
#if defined GBUFFERS_LINE
	isLine = 0.1;
#endif

vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

vec3 viewPos0 = viewPos.xyz;
vec3 viewPos1 = getViewPos(depthtex1, uv).xyz;

vec3 relPos0 = worldPos.xyz;
vec3 relPos1 = getRelPos(depthtex1, uv).xyz;

vec3 fragPos0 = relPos0 + cameraPosition;
vec3 fragPos1 = relPos1 + cameraPosition;

vec3 pos0 = normalize(relPos0);
vec3 pos1 = normalize(relPos1);

vec2 pomUV = uv0;
float pomShadows = getParallaxUVAndShadows(relPos0, sunPos, pomUV);

vec4 translucent = vec4(0.0, 0.0, 0.0, 0.0);
vec3 bloom = vec3(0.0, 0.0, 0.0);
float vanillaAO = 0.0;
#if defined USE_TEXTURES
	vec4 albedo = texture(gtexture, pomUV);
#	if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
		if (abs(col.r - col.g) > 0.001 || abs(col.g - col.b) > 0.001) albedo *= vec4(normalize(col.rgb), col.a);
		vanillaAO = 1.0 - (col.g * 2.0 - (col.r < col.b ? col.r : col.b));
#	else
		albedo *= col;
#	endif
#else
	vec4 albedo = col;
#endif

#if defined USE_ALPHA_TEST
	if (albedo.a < alphaTestRef) discard;
#endif

#if defined GBUFFERS_ENTITIES
	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif

#if defined GBUFFERS_WEATHER
//	albedo.rgb = vec3(getLuma(albedo.rgb));
#endif

float height = 0.0;
vec3 fNormal = 
#if !defined GBUFFERS_SKYBASIC
	vNormal;
#	if defined USE_TEXTURES && defined MC_NORMAL_MAP && PBR_TEXTURE == LAB_PBR
		fNormal = vec3(texture(normals, pomUV).rg * 2.0 - 1.0, sqrt(1.0 - dot(texture(normals, pomUV).rg * 2.0 - 1.0, texture(normals, pomUV).rg * 2.0 - 1.0)));
		fNormal = normalize(fNormal * tbnMatrix);
		height = texture(normals, pomUV).a;
#	endif
	if (int(mcEntity) == 1) {
		fNormal = normalize(getWaterWaveNormal(getWaterParallax(tbnMatrix * viewPos0, fragPos0.xz)) * tbnMatrix);
	}
	fNormal = mat3(gbufferModelViewInverse) * fNormal;
#else
	normalize(getRelPos(depthtex0, uv).rgb);
#endif

#if defined GBUFFERS_LINE || defined GBUFFERS_BASIC
	fNormal = vec3(0.0, 1.0, 0.0);
#endif

#if defined GBUFFERS_BASIC
	if (renderStage != MC_RENDER_STAGE_DEBUG) {
		fNormal = vec3(0.0, 1.0, 0.0);
	}
#endif

float perceptualSmoothness = 0.0;
float roughness = 0.0;
float emissive = 0.0;
float reflectance = 0.0;

#if defined USE_TEXTURES && defined MC_SPECULAR_MAP && PBR_TEXTURE == LAB_PBR
	perceptualSmoothness = texture(specular, pomUV).r;
	emissive = (texture(specular, pomUV).a * 255.0) < 254.5 ? texture(specular, pomUV).a : 0.0;
	reflectance = texture(specular, pomUV).g;
#endif

#if PBR_TEXTURE == AUTO_GENERATION
	if (int(mcEntity) == 3) emissive = getLuma(albedo.rgb) * getLuma(albedo.rgb);
#endif

if (int(mcEntity) == 1) {
	albedo = vec4(WATER_COL, WATER_TRANSPARENCY);
	reflectance = WATER_REFLECTANCE;
	perceptualSmoothness = 0.8;
}

#ifdef ENABLE_RAIN_RIPPLES
	if (rainStrength > 0.0 && uv1.y > 0.85) {
		fNormal = mix(fNormal, normalize(getRainRipplesNormal(fNormal, fragPos0.xz, rainStrength, frameTimeCounter) * getTBNMatrix(fNormal)), rainStrength * smoothstep(0.85, 1.0, uv1.y));
		reflectance = mix(reflectance, WATER_REFLECTANCE, rainStrength * smoothstep(0.85, 1.0, uv1.y));
		perceptualSmoothness = mix(perceptualSmoothness, 0.8, rainStrength * smoothstep(0.85, 1.0, uv1.y));
	}
#endif

#if defined GBUFFERS_WEATHER
	perceptualSmoothness = 0.0;
	emissive = 0.0;
	reflectance = 0.0;
	fNormal = vec3(0.0, 1.0, 0.0);
#endif

roughness = (1.0 - perceptualSmoothness) * (1.0 - perceptualSmoothness);

bloom = mix(bloom, albedo.rgb, emissive);
#if defined GBUFFERS_SPIDEREYES
	bloom = albedo.rgb;
#endif

#if defined GBUFFERS_CLOUDS && defined ENABLE_SHADER_CLOUDS
	discard;
#endif

#if defined GBUFFERS_TRANSLUCENT
	translucent = albedo;
	albedo.a = 0.0;
#endif

	/* colortex0 (gcolor) */
	fragData0 = albedo;

	/* colortex1 (gdepth) */
	fragData1 = vec4((vNormal + 1.0) * 0.5, 1.0);

	/* colortex2 (gnormal) */
	fragData2 = vec4((fNormal + 1.0) * 0.5, 1.0);

	/* colortex3 (composite) */
	fragData3 = translucent;

	/* colortex4 (gaux1) */
	fragData4 = vec4(uv1, vanillaAO, 1.0);

	/* colortex5 (gaux2) */
	fragData5 = vec4(roughness, emissive, reflectance, 1.0);

	/* colortex8 */
	fragData6 = vec4(int(mcEntity) * 0.1, isLine, height, 1.0);

	/* colortex9 */
	fragData7 = vec4(bloom, 1.0);

} /* main */
#endif /* defined GBUFFERS_FSH */

#if defined GBUFFERS_VSH
//#include "../programmes/attributes/attribute_for_all.glsl"

in vec3 mc_Entity;
in vec4 at_tangent;
in vec2 vaUV0;
in ivec2 vaUV2;
in vec3 vaPosition;
in vec3 vaNormal;
in vec4 vaColor;
in vec2 mc_midTexCoord;

out vec2 uv0;
out vec2 uv1;
out vec2 midUV;
out vec4 vUV0;
out vec4 vUV0AM;
out mat3 tbnMatrix;
out vec4 col;
out vec4 viewPos;
out vec4 worldPos;
out vec3 vNormal;
out vec3 sunPos;
out vec3 moonPos;
out vec3 shadowLightPos;
out float mcEntity;

void main() {
uv0 = 
#if defined USE_TEXTURES
	(textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
#else
	vec2(0.0, 0.0);
#endif
uv1 = 
#if defined USE_LIGHTMAP
	clamp(vaUV2 / 256.0, vec2(0.03125 /* 0.5 / 16.0 */), vec2(0.96875 /* 15.5 / 16.0 */));
#else
	vec2(0.0, 0.0);
#endif

midUV = (textureMatrix * vec4(mc_midTexCoord, 0.0, 1.0)).xy;
vec2 halfCoord = uv0 - midUV;
vUV0AM.pq = abs(halfCoord) * 2;
vUV0AM.st = min(uv0, midUV - halfCoord);
vUV0.xy = sign(halfCoord) * 0.5 + 0.5;

col = vaColor;

worldPos = vec4(vaPosition, 1.0);
#if defined USE_CHUNK_OFFSET
	worldPos.xyz += chunkOffset;
#endif

viewPos = modelViewMatrix * worldPos;

vec3 tangent  = normalize(normalMatrix * at_tangent.xyz);
vec3 binormal = normalize(normalMatrix * cross(at_tangent.xyz, vaNormal) * at_tangent.w);

vNormal    = normalize(normalMatrix * vaNormal);
tbnMatrix  = transpose(mat3(tangent, binormal, vNormal));

sunPos = normalize(mat3(gbufferModelViewInverse) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * moonPosition);
shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

mcEntity = 0.1;
#if defined GBUFFERS_TRANSLUCENT
	if (int(mc_Entity.x) == 10001) mcEntity = 1.1; // Water
#endif
if (int(mc_Entity.x) == 10002) {
	mcEntity = 2.1; // Foliage
	vec3 wavPos = worldPos.xyz + cameraPosition;
	vec2 wav = vec2(sin(frameTimeCounter * 2.5 + 2.0 * wavPos.x + wavPos.y), sin(frameTimeCounter * 2.5 + 2.0 * wavPos.z + wavPos.y));
	float wind = sin(frameTimeCounter * 0.5 + wavPos.x * 0.02 + wavPos.y * 0.08 + wavPos.z * 0.1) * mix(WIND_POWER, WIND_POWER_RAINY, rainStrength);

	worldPos.zx += wav * 0.025 * wind * smoothstep(0.7, 1.0, uv1.y);
} else if (int(mc_Entity.x) == 10003) {
	mcEntity = 3.1; // Emissive
}

#if defined GBUFFERS_LINE
	const float LINE_WIDTH  = 2.0;
	const float VIEW_SHRINK = 0.99609375 /* 1.0 - (1.0 / 256.0) */ ;
	const mat4 VIEW_SCALE   = mat4(VIEW_SHRINK, 0.0, 0.0, 0.0,
								   0.0, VIEW_SHRINK, 0.0, 0.0,
								   0.0, 0.0, VIEW_SHRINK, 0.0,
								   0.0, 0.0, 0.0, 1.0);

	vec2 resolution   = vec2(viewWidth, viewHeight);
	vec4 linePosStart = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition, 1.0)));
	vec4 linePosEnd   = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition + vaNormal, 1.0)));

	vec3 ndc1 = linePosStart.xyz / linePosStart.w;
	vec3 ndc2 = linePosEnd.xyz   / linePosEnd.w;

	vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * resolution);
	vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * LINE_WIDTH / resolution;

	if (lineOffset.x < 0.0) lineOffset = -lineOffset;
	if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;

		gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
#else
		gl_Position = projectionMatrix * (modelViewMatrix * worldPos);
#endif
} /* main */
#endif /* defined GBUFFERS_VSH */

#endif /* !defined GBUFFERS_GLSL_INCLUDED */