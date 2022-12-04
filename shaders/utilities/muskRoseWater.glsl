#if !defined WATER_INCLUDED
#define WATER_INCLUDED 1

uniform sampler2D noisetex;

const int noiseTextureResolution = 256;

float textureNoise(const vec2 pos) {
    return texture2D(noisetex, pos / float(noiseTextureResolution)).r;
}

/*
 ** Simplex Noise modded by Rin
 ** Original author: Ashima Arts (MIT License)
 ** See: https://github.com/ashima/webgl-noise
 **      https://github.com/stegu/webgl-noise
*/
vec2 mod289(vec2 x) {
    return x - floor(x * 1.0 / 289.0) * 289.0;
}
vec3 mod289(vec3 x) {
    return x - floor(x * 1.0 / 289.0) * 289.0;
}
vec3 permute289(vec3 x) {
    return mod289((x * 34.0 + 1.0) * x);
}
float simplexNoise(vec2 v) {
    const vec4 c = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);

    vec2 i  = floor(v + dot(v, c.yy));
    vec2 x0 = v -   i + dot(i, c.xx);

    vec2 i1  = x0.x > x0.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + c.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute289(permute289(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m *= m * m * m;

    vec3 x  = 2.0 * fract(p * c.www) - 1.0;
    vec3 h  = abs(x) - 0.5;
    vec3 ox = round(x);
    vec3 a0 = x - ox;

    m *= inversesqrt(a0 * a0 + h * h);

    vec3 g;
    g.x  = a0.x  * x0.x   + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    
    return 130.0 * dot(m, g);
}

#define ENABLE_WATER_WAVES

/*
 ** Generate water waves with simplex noises.
*/
float getWaterWav(const vec2 pos, const float time) {
	float wav = 0.0;
    #ifdef ENABLE_WATER_WAVES
        vec2 p = pos * 0.5;

        wav += simplexNoise(vec2(p.x * 1.4 - time * 0.4, p.y + time * 0.4) * 0.6) * 4.0;
        wav += simplexNoise(vec2(p.x * 1.4 - time * 0.3, p.y + time * 0.2) * 1.2) * 1.2;
        wav += simplexNoise(vec2(p.x * 2.2 - time * 0.3, p.y * 2.8 - time * 0.6)) * 0.4;
    #endif

    return wav * 0.004;
}

// #define ENABLE_WATER_PARALLAX

/*
 ** Generate a parallax effect for water (currently crude).
*/
vec2 getWaterParallax(const vec3 viewPos, const vec2 pos, const float time) {
    vec2 paraPos = pos;
    #ifdef ENABLE_WATER_PARALLAX
        float waterHeight = getWaterWav(pos, time);
        paraPos += waterHeight * viewPos.xy;
    #endif

    return paraPos;
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

// #define ENABLE_RAIN_RIPPLES

/*
 ** Generate rain ripples with simplex noises.
*/
float getRipples(const vec2 pos, const float time) {
	float ripples = 0.0;
    #ifdef ENABLE_RAIN_RIPPLES
        vec2 p = pos * 3.0;
        ripples += simplexNoise(vec2(p.x + time * 2.0, p.y - time * 2.0)) * 0.5;
        ripples += simplexNoise(vec2(p.x - time * 1.8, p.y + time * 2.2) * 1.2) * 0.5;
        ripples = (ripples + 0.8) * 0.5;
    #endif

    return ripples * 0.005;
}

/*
 ** Generate a normal map of rain ripples.
*/
vec3 getRippleNormal(const vec2 pos, const float time) {
	const float texStep = 0.05;
    
	float height = getRipples(pos, time);
	vec2  delta  = vec2(height, height);

    delta.x -= getRipples(pos + vec2(texStep, 0.0), time);
    delta.y -= getRipples(pos + vec2(0.0, texStep), time);
    
	return normalize(vec3(delta / texStep, 1.0));
}

#endif /* !defined WATER_INCLUDED */