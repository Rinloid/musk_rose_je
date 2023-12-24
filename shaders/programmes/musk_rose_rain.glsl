#if !defined MUSK_ROSE_RAIN_GLSL_INCLUDED
#define MUSK_ROSE_RAIN_GLSL_INCLUDED

#include "utils/musk_rose_dither.glsl"

/*
 ** Generate ripples based on Ripple Splatter by AntoninHS.
 ** See: https://www.shadertoy.com/view/fdfSzs
*/
vec2 scale(const vec2 pos, const vec2 pivotPoint, const float scale, const float minScale, const float maxScale){
    vec2 p = pos - pivotPoint;
    p *= 1.0 / (max(mix(minScale, maxScale, scale), 0.01));
    p += pivotPoint;

    return p;
}
vec3 offset(const vec2 pos, const vec2 intPos, const vec2 offset, const float time){
    vec2 p = intPos + offset;
    float rand13 = hash12(p + vec2(25.0, 48.0));
    vec2 timeOffsetRand = vec2(hash11(floor(rand13 + time)), hash11(floor(rand13 + time))) + p;
    float rand11 = hash12(timeOffsetRand);
    float rand12 = hash12(timeOffsetRand + vec2(17.0, 33.0));
    vec2 rand21 = vec2(rand11, rand12);
    
    vec2 newPos = pos - offset;
    newPos -= rand21;
    
    float newScale = cos(time + rand11 * 6.28318530718) * 0.5 + 0.5;
    newPos = scale(newPos, vec2(0.5, 0.5), 0.0, 1.0, newScale);
    
    vec3 randPos = vec3(newPos, rand13);

    return randPos;
}
float getRippleSplatter(const vec3 randPos, const float time){
    vec2 p = randPos.xy;
    p += vec2(0.5, 0.5);
    p += clamp(p, vec2(-0.5, -0.5), vec2(0.5, 0.5));

    float cone = 1.0 - distance(p, vec2(0.0, 0.0));
    
    float cycleTime = fract(randPos.z + time);
    float animatedCone = cone + cycleTime;
    float rippleArea = clamp(animatedCone, 0.0, 1.0) - clamp((animatedCone -0.5) * 1.5, 0.0, 1.0);
    float activateRipples = sin(cycleTime * 3.14159265359);
    
    float result = animatedCone * 18.0;
    result = cos(result);
    result *= rippleArea * activateRipples;
    result = clamp(result, 0.0, 1.0);
    
    float randMask = floor(randPos.z + time) + randPos.z * 512.0;
    randMask = step(hash12(vec2(randMask, randMask)), 1.0);

    result *= cone * randMask;
    result = clamp(result, 0.0, 1.0);
    
    return result;
}
float getRipples(const vec2 fragPos, const float time) {
    vec2 p = fragPos * 2.5;
    
    vec3 offset00 = offset(p - floor(p), floor(p), vec2(0.0, 0.0), time);
    vec3 offset01 = offset(p - floor(p), floor(p), vec2(0.0, 1.0), time);
    vec3 offset10 = offset(p - floor(p), floor(p), vec2(1.0, 0.0), time);
    vec3 offset11 = offset(p - floor(p), floor(p), vec2(1.0, 1.0), time);
    
    
    float ripple00 = getRippleSplatter(offset00, time);
    float ripple01 = getRippleSplatter(offset01, time);
    float ripple10 = getRippleSplatter(offset10, time);
    float ripple11 = getRippleSplatter(offset11, time);
    
    float ripples = max(max(ripple00, ripple01), max(ripple10, ripple11));

    return ripples;
}

float getRainRipples(const vec3 worldNormal, const vec2 fragPos, const float rainLevel, const float time) {
    float result = 0.0;

    if (rainLevel > 0.0) {
        result = getRipples(fragPos, time) * mix(0.0, max(0.0, worldNormal.y), rainLevel);
    }

    return result;
}

vec3 getRainRipplesNormal(const vec3 worldNormal, const vec2 fragPos, const float rainLevel, const float time) {
	const float texStep = 5.0;
    
	float height = getRainRipples(worldNormal, fragPos, rainLevel, time) * 5.0;
	vec2  delta  = vec2(height, height);

    delta.x -= getRainRipples(worldNormal, fragPos + vec2(texStep, 0.0), rainLevel, time);
    delta.y -= getRainRipples(worldNormal, fragPos + vec2(0.0, texStep), rainLevel, time);
    
	return normalize(vec3(delta / texStep, 1.0));
}

#endif /* !defined MUSK_ROSE_RAIN_GLSL_INCLUDED */
