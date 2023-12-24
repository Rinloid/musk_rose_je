#if !defined MUSK_ROSE_WATER_GLSL_INCLUDED
#define MUSK_ROSE_WATER_GLSL_INCLUDED

float getWaterMap(const vec2 pos) {
	return 1.0 - texture(colortex12, pos / float(VORONOI_TEXTURE_RESOLUTION)).r;
}

float getWaterWaves(const vec2 pos) {
	float waves = 0.0;
	#ifdef ENABLE_WATER_WAVES
		vec2 p = pos * 35.0;
		float t = frameTimeCounter * WIND_POWER * 25.0;

		waves += getWaterMap(vec2(p.y + t * 0.20, p.x - t * 0.20)) * 5.00;
		waves += getWaterMap(vec2(p.y + t * 0.25, p.x - t * 0.25)) * 2.50;
		waves += getWaterMap(vec2(p.y + t * 0.30, p.x + t * 0.30)) * 2.65;

	#endif

	return waves * WIND_POWER * 0.0035;
}

float getWaterCaustics(const vec2 pos) {
	float caustics = 0.0;
	#ifdef ENABLE_WATER_CAUSTICS
		vec2 p = pos * 35.0;
		float t = frameTimeCounter * WIND_POWER * 25.0;

		caustics += getWaterMap(vec2(p.y + t * 0.2, p.x - t * 0.2));

	#endif

	return 1.0 - caustics;
}

vec3 getWaterWaveNormal(const vec2 pos) {
	const float texStep = 0.2;
    
	float height = getWaterWaves(pos);
	vec2  delta  = vec2(height, height);

    delta.x -= getWaterWaves(pos + vec2(texStep, 0.0));
    delta.y -= getWaterWaves(pos + vec2(0.0, texStep));
    
	return normalize(vec3(delta / texStep, 1.0));
}

#endif /* !defined MUSK_ROSE_WATER_GLSL_INCLUDED */
