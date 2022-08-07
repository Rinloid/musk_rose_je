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

/*
 ** Hash from "Hahs without Sine"
 ** Author: David Hoskins
 ** See: https://www.shadertoy.com/view/4djSRW
*/
float hash13(vec3 p3) {
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);

    return fract((p3.x + p3.y) * p3.z);
}

float getStars(const vec3 pos) {
    vec3 p = floor((normalize(pos) + 16.0) * 265.0);
    float stars = smoothstep(0.998, 1.0, hash13(p));

    return stars;
}

float drawSun(const vec3 pos) {
	return inversesqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
}

float getMoonPhase(const int phase) {
	// 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75
	return float(phase) * 0.25 * 3.14;
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

float drawMoon(const vec3 moonPosition, const float moonPhase, const float moonScale) {
	vec3 lightPosition = vec3(sin(moonPhase), 0.0, -cos(moonPhase));
    float m = diffuseSphere(moonPosition, moonScale, lightPosition);
    
	return m;
}

vec3 toneMapReinhard(const vec3 color) {
	vec3 col = color * color;
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    vec3 exposure = col / (col + 1.0);
	vec3 result = mix(col / (luma + 1.0), exposure, exposure);

    return result;
}

vec3 getSky(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const float brightness) {
	vec3 sky = getAtmosphere(pos, sunPos, skyCol, brightness);

	return toneMapReinhard(sky);
}

#endif /* !defined SKY_INCLUDED */