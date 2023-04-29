#if !defined MUSK_ROSE_SKY_GLSL_INCLUDED
#define MUSK_ROSE_SKY_GLSL_INCLUDED

#include "/utils/musk_rose_clouds.glsl"

/*
 ** Atmoshpere based on one by robobo1221.
 ** See: https://www.shadertoy.com/view/Ml2cWG
*/
vec3 getAbsorption(const vec3 pos, const float posY, const float brightness) {
	vec3 absorption = pos * -posY;
	absorption = exp2(absorption) * brightness;
	
	return absorption;
}
float getSunPoint(const vec3 pos, const vec3 sunPos, const float rainLevel) {
	return smoothstep(0.1, 0.0, distance(pos, sunPos)) * 5.0 * (1.0 - rainLevel);
}
float getRayleig(const vec3 pos, const vec3 sunPos) {
    float dist = 1.0 - clamp(distance(pos, sunPos), 0.0, 1.0);

	return 1.0 + dist * dist * 3.14;
}
float getMie(const vec3 pos, const vec3 sunPos) {
	float disk = clamp(1.0 - pow(distance(pos, sunPos), 0.1), 0.0, 1.0);
	
	return disk * disk * (3.0 - 2.0 * disk) * 2.0 * 3.14;
}
vec3 getAtmosphere(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float brightness) {
	vec3 result = mix(vanillaSkyCol, vanillaFogCol, smoothstep(0.8, 1.0, 1.0 - pos.y));
	#ifdef ENABLE_SHADER_SKY
		float zenith = 0.5 / sqrt(max(pos.y, 0.05));
		
		vec3 absorption = getAbsorption(skyCol, zenith, brightness);
		vec3 sunAbsorption = getAbsorption(skyCol, 1.0 / pow(max(sunPos.y, 0.05), 0.75), brightness);
		vec3 sky = skyCol * zenith * getRayleig(pos, sunPos);
		vec3 mie = getMie(pos, sunPos) * sunAbsorption;
		
		result = mix(sky * absorption, sky / (sky + 0.5), clamp(length(max(sunPos.y, 0.0)), 0.0, 1.0));
		result += mie;
		result *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	#endif

	return result;
}

vec3 getAtmosphereClouds(const vec3 pos, const vec3 cloudPos, const vec3 cameraPos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float brightness, const float daylight, const float rainLevel, const float time) {
	vec3 result = mix(vanillaSkyCol, vanillaFogCol, smoothstep(0.8, 1.0, 1.0 - pos.y));
	#ifdef ENABLE_SHADER_SKY
		const float cloudDensity = 1.50; // [0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00 2.10 2.20 2.30 2.40 2.50 2.60 2.70 2.80 2.90 3.00 3.10 3.20 3.30 3.40 3.50 3.60 3.70 3.80 3.90 4.00 4.10 4.20 4.30 4.40 4.50 4.60 4.70 4.80 4.90 5.00 5.10 5.20 5.30 5.40 5.50 5.60 5.70 5.80 5.90 6.00 6.10 6.20 6.30 6.40 6.50 6.60 6.70 6.80 6.90 7.00 7.10 7.20 7.30 7.40 7.50 7.60 7.70 7.80 7.90 8.00 8.10 8.20 8.30 8.40 8.50 8.60 8.70 8.80 8.90 9.00 9.10 9.20 9.30 9.40 9.50 9.60 9.70 9.80 9.90 10.00]
		
		float zenith = 0.5 / sqrt(max(pos.y, 0.05));
		
		vec3 absorption = getAbsorption(skyCol, zenith, brightness);
		vec3 sunAbsorption = getAbsorption(skyCol, 1.0 / pow(max(sunPos.y, 0.05), 0.75), brightness);
		vec3 sky = skyCol * zenith * getRayleig(pos, sunPos);
		vec3 sun = getSunPoint(pos, sunPos, rainLevel) * absorption;
		vec3 clouds = getClouds(cloudPos, pos, cameraPos, sunPos, time, rainLevel);

		vec3 mie = getMie(pos, sunPos) * sunAbsorption;
		
		result = mix(sky * absorption, sky / (sky + 0.5), clamp(length(max(sunPos.y, 0.0)), 0.0, 1.0));
		
		float cloudBrightness = clamp(dot(result, vec3(0.22, 0.707, 0.071)), 0.0, 1.0);
		vec3 cloudCol = mix(result, vec3(1.0), cloudBrightness);
		cloudCol = mix(cloudCol, vec3(dot(cloudCol, vec3(0.22, 0.707, 0.071))), 0.4);
		
		result = sun + mix(result, mix(cloudCol * mix(1.0, 1.5, clouds.z), cloudCol * mix(0.0, 0.65, daylight), clouds.y), 1.0 / absorption * clouds.x * cloudDensity);
		
		result += mie;
		result *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	#endif

	return result;
}

float getLuma(const vec3 col) {
	return dot(col, vec3(0.22, 0.707, 0.071));
}

vec3 toneMapReinhard(const vec3 color) {
	vec3 col = color * color;
    float luma = getLuma(col);
    vec3 exposure = col / (col + 1.0);
	vec3 result = mix(col / (luma + 1.0), exposure, exposure);

    return result;
}

float getStars(const vec3 pos, const float time) {
    vec3 p = floor((pos + time * 0.001) * 265.0);
    float stars = smoothstep(0.998, 1.0, hash13(p));

    return stars;
}

float getMoonPhase(const int phase) {
	/*
	 ** moonPhase variable: [0, 1, 2, 3, 4, 5, 6, 7]
	 ** Moon in MC:         [4, 5, 6, 7, 0, 1, 2, 3]
	 ** 0 = new moon; 7 = full moon.
	*/
	int correctedPhase = 0 <= phase && phase < 5 ? phase + 4 : phase;

	// [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
	return correctedPhase * 0.25 * 3.14159265359;
}

float diffuseSphere(const vec3 spherePos, const float radius, const vec3 lightPos) {
    float sq = radius * radius - spherePos.x * spherePos.x - spherePos.y * spherePos.y - spherePos.z * spherePos.z;

    if (sq < 0.0) {
        return 0.0;
    } else {
        float z = sqrt(sq);
        vec3 normal = normalize(vec3(spherePos.yx, z));
		
        return max(0.0, dot(normal, lightPos));
    }
}

vec4 getMoon(const vec3 moonPosition, const float moonPhase, const float moonScale) {
	vec3 lightPos = vec3(sin(moonPhase), 0.0, -cos(moonPhase));
    float m = diffuseSphere(moonPosition, moonScale, lightPos);
	float moonTex = mix(1.0, 0.85, clamp(getSimplexNoise(moonPosition.xz * 0.2), 0.0, 1.0));
	m = smoothstep(0.0, 0.3, m) * moonTex;
    
	return vec4(mix(vec3(0.1, 0.05, 0.01), vec3(1.0, 0.95, 0.81), m), diffuseSphere(moonPosition, moonScale, vec3(0.0, 0.0, 1.0)));
}

vec3 getSky(const vec3 pos, const vec3 cloudPos, const vec3 camPos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float daylight, const float rainLevel, const float time, const int moonPhase) {
	vec3 sky = getAtmosphereClouds(pos, cloudPos, camPos, sunPos, skyCol, vanillaSkyCol, vanillaFogCol, mix(0.5, 2.0, smoothstep(0.0, 0.1, daylight)), daylight, rainLevel, time);
	vec4 moon = getMoon(cross(pos, -sunPos) * 127.0, getMoonPhase(moonPhase), 7.0);
	moon.a = mix(moon.a, 0.0, rainLevel);

	sky = toneMapReinhard(sky);
	sky = mix(sky, vec3(1.0), getStars(pos, time) * (1.0 - smoothstep(0.0, 0.3, daylight)) * (1.0 - rainLevel));
	sky = mix(sky, moon.rgb, moon.a * smoothstep(0.1, 0.0, daylight));
	sky = mix(sky, vec3(getLuma(sky)), rainLevel);

	return sky;
}

#endif /* !defined MUSK_ROSE_SKY_GLSL_INCLUDED */