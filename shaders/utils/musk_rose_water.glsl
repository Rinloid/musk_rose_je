#if !defined MUSK_ROSE_WATER_GLSL_INCLUDED
#define MUSK_ROSE_WATER_GLSL_INCLUDED

#include "/utils/musk_rose_noise.glsl"

#define ENABLE_WAVES
float getWaterWaves(const vec2 pos, const float time) {
	float waves = 0.0;
	#ifdef ENABLE_WAVES
		vec2 p = pos * 0.16;
		float t = time * 0.16;

        waves += getWaterNoise(vec2(p.y * 0.20 + t * 0.10, p.x * 0.50 + t * 0.10)) * 2.00;
		waves += getWaterNoise(vec2(p.y * 0.25 + t * 0.15, p.x * 0.45 - t * 0.15)) * 1.50;
		waves += getWaterNoise(vec2(p.y * 0.30 + t * 0.20, p.x * 0.50 + t * 0.20)) * 1.65;
		waves += getWaterNoise(vec2(p.y * 0.50 + t * 0.50, p.x * 0.45 + t + 0.50)) * 1.20;
		waves += getWaterNoise(vec2(p.y * 0.50 + t * 0.45, p.x * 0.50 - t + 0.45)) * 1.10;

	#endif

	return waves * 0.03;
}

float getWaterWavesCaustic(const vec2 pos, const float time) {
	float waves = 0.0;
	#ifdef ENABLE_WAVES
		vec2 p = pos * 0.16;
		float t = time * 0.16;

        waves += getWaterNoise(vec2(p.y * 0.20 + t * 0.10, p.x * 0.50 + t * 0.10)) * 1.80;
		waves += getWaterNoise(vec2(p.y * 0.30 + t * 0.20, p.x * 0.50 + t * 0.20)) * 1.65;
		waves += getWaterNoise(vec2(p.y * 0.50 + t * 0.45, p.x * 0.50 - t + 0.45)) * 1.10;
	#endif

	return waves * 0.25;
}

vec3 getWaterWaveNormal(const vec2 pos, const float time) {
	const float texStep = 0.2;
    
	float height = getWaterWaves(pos, time);
	vec2  delta  = vec2(height, height);

    delta.x -= getWaterWaves(pos + vec2(texStep, 0.0), time);
    delta.y -= getWaterWaves(pos + vec2(0.0, texStep), time);
    
	return normalize(vec3(delta / texStep, 1.0));
}

/*
 ** Generate a parallax effect for water (currently crude).
*/
// #define ENABLE_WATER_PARALLAX
vec2 getWaterParallax(const vec3 viewPos, const vec2 pos, const float time) {
    vec2 paraPos = pos;
    #ifdef ENABLE_WATER_PARALLAX
        float waterHeight = getWaterWaves(pos, time);
        paraPos += waterHeight * viewPos.xy;
    #endif

    return paraPos;
}

#endif /* !defined MUSK_ROSE_WATER_GLSL_INCLUDED */