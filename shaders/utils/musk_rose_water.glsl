#if !defined MUSK_ROSE_WATER_GLSL_INCLUDED
#define MUSK_ROSE_WATER_GLSL_INCLUDED

#include "/utils/musk_rose_hash.glsl"

#define ENABLE_WAVES
float getWaterWaves(const vec2 pos, const float time) {
	float waves = 0.0;
	#ifdef ENABLE_WAVES
		vec2 p = pos * 35.0;
		float t = time * 50.0;

		waves += getWaterNoise(vec2(p.y + t * 0.20, p.x - t * 0.20)) * 5.00;
		waves += getWaterNoise(vec2(p.y + t * 0.25, p.x - t * 0.25)) * 2.50;
		waves += getWaterNoise(vec2(p.y + t * 0.30, p.x + t * 0.30)) * 2.65;

	#endif

	return waves * 0.005;
}

#define ENABLE_CAUSTICS
float getWaterCaustics(const vec2 pos, const float time) {
	float caustics = 0.0;
	#ifdef ENABLE_CAUSTICS
		vec2 p = pos * 35.0;
		float t = time * 50.0;

		caustics += getWaterNoise(vec2(p.y + t * 0.2, p.x - t * 0.2));

	#endif

	return 1.0 - caustics;
}

vec3 getWaterWaveNormal(const vec2 pos, const float time) {
	const float texStep = 0.2;
    
	float height = getWaterWaves(pos, time);
	vec2  delta  = vec2(height, height);

    delta.x -= getWaterWaves(pos + vec2(texStep, 0.0), time);
    delta.y -= getWaterWaves(pos + vec2(0.0, texStep), time);
    
	return normalize(vec3(delta / texStep, 1.0));
}

// #define ENABLE_WATER_PARALLAX
vec2 getWaterParallax(const vec3 viewPos, const vec2 pos, const float time) {
	const int parallaxSteps = 8;

    vec2 paraPos = pos;
	float waterHeight = 0.0;
    #ifdef ENABLE_WATER_PARALLAX
		for (int i = 0; i < parallaxSteps; i++) {
			paraPos += waterHeight * viewPos.xy / length(viewPos) * (1.0 / float(parallaxSteps));
			waterHeight += getWaterWaves(paraPos, time) * 8.0;
		}
    #endif

    return paraPos;
}

#endif /* !defined MUSK_ROSE_WATER_GLSL_INCLUDED */