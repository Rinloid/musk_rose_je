#if !defined SHADOW_INCLUDED
#define SHADOW_INCLUDED 1

/*
 ** Shadow distortion based on Shadow Tutorial.  Visit shaderLABS for details.
 ** https://discord.gg/KJ2SXNkKqS
*/
float cubeLength(vec2 v) {
	return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
}
float getDistortFactor(vec2 v) {
	return cubeLength(v) + 0.05;
}
vec3 distort(vec3 v, float factor) {
	return vec3(v.xy / factor, v.z * 0.5);
}
vec3 distort(vec3 v) {
	return distort(v, getDistortFactor(v.xy));
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