#if !defined MUSK_ROSE_SHADOW_GLSL_INCLUDED
#define MUSK_ROSE_SHADOW_GLSL_INCLUDED

const vec2 shadowSamples[16] = vec2[16](
	  vec2(-0.220147, 0.976896),
	  vec2(-0.735514, 0.693436),
	  vec2(-0.200476, 0.310353),
	  vec2( 0.180822, 0.454146),
	  vec2( 0.292754, 0.937414),
	  vec2( 0.564255, 0.207879),
	  vec2( 0.178031, 0.024583),
	  vec2( 0.613912,-0.205936),
	  vec2(-0.385540,-0.070092),
	  vec2( 0.962838, 0.378319),
	  vec2(-0.886362, 0.032122),
	  vec2(-0.466531,-0.741458),
	  vec2( 0.006773,-0.574796),
	  vec2(-0.739828,-0.410584),
	  vec2( 0.590785,-0.697557),
	  vec2(-0.081436,-0.963262));

/*
 ** Shadow distortion by Builderb0y.
 ** https://discord.gg/KJ2SXNkKqS
*/

float getDistortFactor(const vec2 pos) {
	return pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 1.0 / 3.0) + SHADOW_DISTROTION;
}
vec3 distort(const vec3 pos, const float factor) {
	return vec3(pos.xy / factor, pos.z * 0.5);
}
vec3 distort(const vec3 pos) {
	return distort(pos, pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 1.0 / 3.0) + SHADOW_DISTROTION);
}

#endif /* !defined MUSK_ROSE_SHADOW_GLSL_INCLUDED */