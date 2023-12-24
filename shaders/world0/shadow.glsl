#include "../programmes/musk_rose_config.glsl"
#include "../programmes/utils/musk_rose_shadow.glsl"

#if !defined SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED
#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_gbuffers.glsl"

#if defined SHADOW_FSH
#extension GL_ARB_explicit_attrib_location : enable

in vec2 uv0;
in vec4 col;
in vec3 fragPos;
in float mcEntity;

#include "../programmes/musk_rose_water.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 fragData0;

void main() {
vec4 albedo = texture(gtexture, uv0) * col;
if (albedo.a < alphaTestRef) discard;

if (int(mcEntity) == 1) {
	float caustics = pow(getWaterCaustics(fragPos.xz), 0.2);
	albedo = mix(vec4(1.0, 1.0, 1.0, 0.0), vec4(WATER_COL, 0.5), clamp(caustics, 0.0, 1.0));
}

	/* colortex0 (gcolor) */
	fragData0 = albedo;
} /* main */
#endif /* defined SHADOW_FSH */

#if defined SHADOW_VSH
in vec3 mc_Entity;
in vec2 vaUV0;
in vec3 vaPosition;
in vec3 vaNormal;
in vec4 vaColor;

out vec2 uv0;
out vec4 col;
out vec3 fragPos;
out float mcEntity;

void main() {
uv0 = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
col = vaColor;
mcEntity = 0.1;
if (int(mc_Entity.x) == 10001) mcEntity = 1.1; // Water

vec4 worldPos = vec4(vaPosition + chunkOffset, 1.0);
fragPos = (shadowModelViewInverse * (shadowProjectionInverse * projectionMatrix * (modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0)))).xyz + cameraPosition;

	gl_Position = projectionMatrix * (modelViewMatrix * worldPos);
	gl_Position.xyz = distort(gl_Position.xyz);
} /* main */
#endif /* defined SHADOW_VSH */

#endif /* !defined SHADOW_GLSL_INCLUDED */