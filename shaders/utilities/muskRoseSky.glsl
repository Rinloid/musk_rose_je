#if !defined SKY_INCLUDED
#define SKY_INCLUDED 1

/*
 ** Atmoshpere based on one by robobo1221.
 ** See: https://www.shadertoy.com/view/Ml2cWG
*/
vec3 getAbsorption(const vec3 pos, const float posY, const float brightness) {
	vec3 absorption = pos * -posY;
	absorption = exp2(absorption) * brightness;
	
	return absorption;
}
float getRayleig(const vec3 pos, const vec3 sunPos) {
    float dist = 1.0 - clamp(distance(pos, sunPos), 0.0, 1.0);

	return 1.0 + dist * dist * 3.14;
}
float getMie(const vec3 pos, const vec3 sunPos) {
	float disk = clamp(1.0 - pow(distance(pos, sunPos), 0.1), 0.0, 1.0);
	
	return disk * disk * (3.0 - 2.0 * disk) * 2.0 * 3.14;
}
vec3 getAtmosphere(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const float brightness) {
	float zenith = 0.5 / sqrt(max(pos.y, 0.05));
	
	vec3 absorption = getAbsorption(skyCol, zenith, brightness);
    vec3 sunAbsorption = getAbsorption(skyCol, 0.5 / pow(max(sunPos.y, 0.05), 0.75), brightness);
	vec3 sky = skyCol * zenith * getRayleig(pos, sunPos);

	vec3 mie = getMie(pos, sunPos) * sunAbsorption;
	
	vec3 result = mix(sky * absorption, sky / (sky + 0.5), clamp(length(max(sunPos.y, 0.0)), 0.0, 1.0));
    result += mie;
	result *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	
	return result;
}
#include "muskRoseClouds.glsl"
vec3 getAtmosphereClouds(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const float rain, const float brightness, const float daylight, const float time) {
	float zenith = 0.5 / sqrt(max(pos.y, 0.05));
	
	vec3 absorption = getAbsorption(skyCol, zenith, brightness);
    vec3 sunAbsorption = getAbsorption(skyCol, 0.5 / pow(max(sunPos.y, 0.05), 0.75), brightness);
	vec3 sky = skyCol * zenith * getRayleig(pos, sunPos);
	vec2 clouds = renderClouds(pos, cameraPosition, sunPos, daylight, rain, time);

	vec3 mie = getMie(pos, sunPos) * sunAbsorption;
	
	vec3 result = mix(sky * absorption, sky / (sky + 0.5), clamp(length(max(sunPos.y, 0.0)), 0.0, 1.0));
	
	float cloudBrightness = clamp(dot(result, vec3(0.4)), 0.0, 1.0);
	vec3 cloudCol = mix(result, vec3(1.0), cloudBrightness);
	cloudCol = mix(cloudCol, vec3(dot(cloudCol, vec3(0.4))), 0.4);
	
	result = mix(result, mix(cloudCol, cloudCol * 0.8, clouds.y), 1.0 / absorption * clouds.x * 1.0);
	
    result += mie;
	result *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	
	return result;
}

#include "muskRoseHash.glsl"

float getStars(const vec3 pos) {
    vec3 p = floor((normalize(pos) + 16.0) * 265.0);
    float stars = smoothstep(0.998, 1.0, hash13(p));

    return stars;
}

float getSun(const vec3 pos) {
	return 1.0 / length(pos);
}

float getMoonPhase(const int phase) {
	// moonPhase variable: [0, 1, 2, 3, 4, 5, 6, 7]
	// Moon in MC:         [4, 5, 6, 7, 0, 1, 2, 3]
	// 0 = new moon, 7 = full moon.
	int correctedPhase = 0 <= phase && phase < 5 ? phase + 4 : phase;

	// [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
	return correctedPhase * 0.25 * 3.14;
}

float diffuseSphere(const vec3 spherePosition, const float radius, const vec3 lightPosition) {
    float sq = radius * radius - spherePosition.x * spherePosition.x - spherePosition.y * spherePosition.y - spherePosition.z * spherePosition.z;

    if (sq < 0.0) {
        return 0.0;
    } else {
        float z = sqrt(sq);
        vec3 normal = normalize(vec3(spherePosition.yx, z));
		
        return max(0.0, dot(normal, lightPosition));
    }
}

vec4 getMoon(const vec3 moonPosition, const float moonPhase, const float moonScale) {
	vec3 lightPosition = vec3(sin(moonPhase), 0.0, -cos(moonPhase));
    float m = diffuseSphere(moonPosition, moonScale, lightPosition);
	float moonTex = mix(1.0, 0.85, clamp(simplexNoise(moonPosition.xz * 0.1), 0.0, 1.0));
	m = smoothstep(0.0, 0.3, m) * moonTex;
    
	return vec4(mix(vec3(0.1, 0.05, 0.01), vec3(1.0, 0.95, 0.81), m), diffuseSphere(moonPosition, moonScale, vec3(0.0, 0.0, 1.0)));
}

vec3 toneMapReinhard(const vec3 color) {
	vec3 col = color * color;
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    vec3 exposure = col / (col + 1.0);
	vec3 result = mix(col / (luma + 1.0), exposure, exposure);

    return result;
}

vec3 getSky(const vec3 pos, const vec3 sunPos, const vec3 moonPos, const vec3 skyCol, const float daylight, const float rain, const float time, const int moonPhase) {
	vec3 sky = getAtmosphereClouds(pos, sunPos, skyCol, rain, mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight)), daylight, time);
	vec4 moon = getMoon(cross(pos, moonPos) * 127.0, getMoonPhase(moonPhase), 7.0);
	moon = mix(moon, vec4(0.0), rain);
	float sunTrim =
#	if !defined WORLD1
		smoothstep(0.1, 0.0, distance(pos, sunPos));
#	else
		1.0;
	#endif
	sky = toneMapReinhard(sky);
	sky = mix(sky, moon.rgb, moon.a * smoothstep(0.1, 0.0, daylight) * smoothstep(0.2, 0.1, distance(pos, moonPos)));
	sky += mix(vec3(0.0), vec3(daylight), getSun(cross(pos, sunPos) * 25.0) * smoothstep(0.0, 0.01, daylight) * sunTrim);
	sky = mix(sky, vec3(1.0, 0.96, 0.82), getStars(pos) * smoothstep(0.4, 0.0, daylight));

	sky = mix(sky, vec3(dot(sky, vec3(0.4))), rain);
	
	return sky;
}

vec3 getSkyLight(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const float daylight, const float rain) {
	vec3 sky = getAtmosphere(pos, sunPos, skyCol, mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight)));
	sky = toneMapReinhard(sky);

	sky = mix(sky, vec3(dot(sky, vec3(0.4))), rain);

	return sky;
}

#endif /* !defined SKY_INCLUDED */