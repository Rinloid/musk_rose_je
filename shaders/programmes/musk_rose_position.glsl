#if !defined MUSK_ROSE_POSITION_GLSL_INCLUDED
#define MUSK_ROSE_POSITION_GLSL_INCLUDED

vec4 getViewPos(const sampler2D depthTex, const vec2 uv) {
	vec4 viewPos = gbufferProjectionInverse * vec4(vec3(uv, texture(depthTex, uv).r) * 2.0 - 1.0, 1.0);

	return viewPos / viewPos.w;
}

vec4 getScreenPos(const vec3 pos) {
	vec4 viewPos = gbufferProjection * vec4(pos, 1.0);

	return viewPos / viewPos.w * 0.5 + 0.5;
}

vec4 getRelPos(const sampler2D depthTex, const vec2 uv) {
	return gbufferModelViewInverse * getViewPos(depthTex, uv);
}

#include "utils/musk_rose_shadow.glsl"

vec4 getShadowPos(const vec4 worldPos, const float diffuse) {
	vec4 shadowPos = vec4(worldPos.xyz, 1.0);
	shadowPos = shadowProjection * (shadowModelView * shadowPos);
	
	float distortFactor = getDistortFactor(shadowPos.xy);
	shadowPos.xyz = distort(shadowPos.xyz);
	shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;

	shadowPos.z -= SHADOW_BIAS * (distortFactor * distortFactor) / abs(diffuse);

	return shadowPos;
}

#endif /* !defined MUSK_ROSE_POSITION_GLSL_INCLUDED */