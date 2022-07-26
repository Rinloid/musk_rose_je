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

float getSunSpot(const vec3 pos, const vec3 sunPos) {
	return smoothstep(0.03, 0.025, distance(pos, sunPos)) * 25.0;
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
	float zenith = 0.5 / pow(max(pos.y, 0.05), 0.5);
	
	vec3 absorption = getAbsorption(skyCol, zenith, brightness);
    vec3 sunAbsorption = getAbsorption(skyCol, 0.5 / pow(max(sunPos.y, 0.05), 0.75), brightness);
	vec3 sky = skyCol * zenith * getRayleig(pos, sunPos);
	vec3 sun = getSunSpot(pos, sunPos) * absorption;
	vec3 mie = getMie(pos, sunPos) * sunAbsorption;
	
	vec3 result = mix(sky * absorption, sky / (sky + 0.5), clamp(length(max(sunPos.y, 0.0)), 0.0, 1.0));
    result += sun + mie;
	result *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	
	return result;
}

float drawSun(const vec3 pos) {
	return inversesqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
}

vec3 toneMapReinhard(const vec3 color) {
	vec3 col = color * color;
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    vec3 exposure = col / (col + 1.0);
	vec3 result = mix(col / (luma + 1.0), exposure, exposure);

    return result;
}

#endif /* !defined SKY_INCLUDED */