#if !defined SHADOW_INCLUDED
#define SHADOW_INCLUDED 1

/*
 ** Shadow distortion based on Shadow Tutorial.
 ** Visit shaderLABS for details.
 ** https://discord.gg/KJ2SXNkKqS
*/
float getDistortFact(const vec2 shadowPos) {
    float cubeLength = pow(abs(shadowPos.x * shadowPos.x * shadowPos.x) + abs(shadowPos.y * shadowPos.y * shadowPos.y), 0.33 /* 1.0 / 3.0 */);

	return cubeLength + 0.05;
}
vec3 distort(const vec3 shadowPos, const float fact) {
	return vec3(shadowPos.xy / fact, shadowPos.z * 0.5);
}
vec3 distort(const vec3 shadowPos) {
	return distort(shadowPos, getDistortFact(shadowPos.xy));
}

#endif /* !defined SHADOW_INCLUDED */