#if !defined SHADOW_INCLUDED
#define SHADOW_INCLUDED 1

/*
 ** Shadow distortion based on Shadow Tutorial.
 ** Visit shaderLABS for details.
 ** https://discord.gg/KJ2SXNkKqS
*/
float getDistortFactor(const vec2 shadowPos) {
    float cubeLength = pow(abs(shadowPos.x * shadowPos.x * shadowPos.x) + abs(shadowPos.y * shadowPos.y * shadowPos.y), 0.33 /* 1.0 / 3.0 */);

	return cubeLength + 0.05;
}
vec3 distort(const vec3 shadowPos, const float factor) {
	return vec3(shadowPos.xy / factor, shadowPos.z * 0.5);
}
vec3 distort(const vec3 shadowPos) {
	return distort(shadowPos, getDistortFactor(shadowPos.xy));
}

const vec2[8] shadowSamples = vec2[8] (
    vec2(-0.5337560, 0.5918049),
    vec2(-0.5887652, 0.2827983),
    vec2(-0.1112829, 0.8347653),
    vec2(-0.1763154, 0.4841528),
    vec2(0.14189000, 0.3237082),
    vec2(0.28009290, 0.9120663),
    vec2(0.10938630, 0.6212762),
    vec2(-0.9064262, -0.118388)
);

#endif /* !defined SHADOW_INCLUDED */