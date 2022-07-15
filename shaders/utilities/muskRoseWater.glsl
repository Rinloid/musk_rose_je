#include "noiseFunctions.glsl"

/*
 ** Generate water waves with simplex noises.
*/
float getWaterWav(const vec2 pos, const float time) {
	float wav = 0.0;
    vec2  p   = pos;

    wav += simplexNoise(vec2(p.x * 1.4 - time * 0.4, p.y * 0.65 + time * 0.4) * 0.6) * 3.0;
    wav += simplexNoise(vec2(p.x * 1.0 + time * 0.6, p.y - time * 0.75)) * 0.5;
    wav += simplexNoise(vec2(p.x * 2.2 - time * 0.3, p.y * 2.8 - time * 0.6)) * 0.25;

    /*
     ** The scale should be very small?
    */
	return wav * 0.005;
}

/*
 ** Generate a normal map of water waves.
*/
vec3 getWaterWavNormal(const vec2 pos, const float time) {
	const float texStep = 0.04;
    
	float height = getWaterWav(pos, time);
	vec2  delta  = vec2(height, height);

    delta.x -= getWaterWav(pos + vec2(texStep, 0.0), time);
    delta.y -= getWaterWav(pos + vec2(0.0, texStep), time);
    
	return normalize(vec3(delta / texStep, 1.0));
}