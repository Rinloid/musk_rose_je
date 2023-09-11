#if !defined MUSK_ROSE_SKYMIE_DIRECTIONLSL_INCLUDED
#define MUSK_ROSE_SKYMIE_DIRECTIONLSL_INCLUDED

#include "/utils/musk_rose_hash.glsl"

float getFluffyClouds(const vec2 pos, const float amp, const float lower, const float upper, const float time, const float rainLevel, const int octaves) {
    float v = 0.0;
    float amptitude = amp;
	vec2 x = pos * 4.0;

    x += time * 0.1;

    for (int i = 0; i < octaves; i++) {
        v += amptitude * (getCloudNoise(x) * 0.5 + 0.5);

        if (v >= upper) {
            break;
        } else if (v + amptitude <= lower) {
            break;
        }

        x         *= 2.0;
        x.y       -= float(i + 1) * time * 0.5;
        amptitude *= 0.5;
    }

	return smoothstep(mix(lower, 0.0, rainLevel), mix(upper, 1.0, rainLevel), v);
}

float getBlockyClouds(const vec2 pos, const float frameTime, const float rainLevel) {
    vec2 p = pos * 0.5;
    p += frameTime * 0.02;
    float body = hashTex(floor(p));
    body = body > mix(0.7, -1.0, rainLevel) ? 1.0 : 0.0;

    return body;
}

//#define ENABLE_BLOCKY_CLOUDS

vec2 getClouds(const vec3 pos, const vec3 sunPos, const vec2 screenPos, const float frameTime, const float rainLevel) {
#   if defined CLOUDS_QUALITY_LOW
        #ifdef ENABLE_BLOCKY_CLOUDS
            const int cloudSteps = 16;
            const float cloudStepSize = 0.012;
            const int raySteps = 8;
            const float rayStepSize = 0.08;
        #else
            const int cloudSteps = 12;
            const float cloudStepSize = 0.016;
            const int raySteps = 8;
            const float rayStepSize = 0.04;
        #endif
#   else
        #ifdef ENABLE_BLOCKY_CLOUDS
            const int cloudSteps = 32;
            const float cloudStepSize = 0.006;
            const int raySteps = 16;
            const float rayStepSize = 0.04;
        #else
            const int cloudSteps = 24;
            const float cloudStepSize = 0.032;
            const int raySteps = 8;
            const float rayStepSize = 0.04;
    #endif
#   endif
    const float cloudHeight = 256.0;

    vec2 totalClouds = vec2(0.0, 0.0);
    float clouds = 0.0;
    float shade  = 0.0;
    float highlight = 0.0;

    float amp = 0.475;

    float drawSpace = max(0.0, length(pos.xz / (pos.y * float(10))));
    if (drawSpace < 1.0 && !bool(step(pos.y, 0.0))) {
        for (int i = 0; i < cloudSteps; i++) {
            float height = 1.0 + float(i) * cloudStepSize;
            vec3 p = pos.xyz / pos.y * height;
            #ifdef ENABLE_BLOCKY_CLOUDS
                clouds += getBlockyClouds(p.xz * 4.0, frameTime, rainLevel);
            #else
                clouds += getFluffyClouds(p.xz * 4.0, abs(amp), 0.7, 0.75, frameTime, rainLevel, 6);
            #endif

            if (clouds > 0.0) {
                vec3 rayPos = (pos.xyz / pos.y * height) - sunPos * rayStepSize;
                float ray = 0.0;
                for (int j = 0; j < raySteps; j++) {
                    #ifdef ENABLE_BLOCKY_CLOUDS
                        ray += getBlockyClouds(rayPos.xz * 4.0, frameTime, rainLevel) / float(raySteps);
                    #else
                        ray += getFluffyClouds(rayPos.xz * 4.0, abs(amp), 0.7, 1.0, frameTime, rainLevel, 5) * 2.0;
                    #endif
                    rayPos += sunPos * rayStepSize;
                }
                shade += ray;
            }
            amp -= 0.12 / float(cloudSteps);
        } clouds /= float(cloudSteps);
          shade /= float(cloudSteps);

        clouds = mix(clouds, 0.0, drawSpace);
    }

    totalClouds = vec2(clouds, shade);
    totalClouds *= bayerX64(screenPos) * 0.5 + 0.5;

    return totalClouds;
}

float getLuma(const vec3 col) {
    return dot(col, vec3(0.22, 0.707, 0.071));
}

uniform sampler2D colortex13, colortex12;

vec3 getAtmosphere(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 uv, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir) {
    vec3 totalAtmosphere = vec3(0.0, 0.0, 0.0);
    vec3 totalMie        = vec3(0.0, 0.0, 0.0);
    vec3 totalRayleigh   = vec3(0.0, 0.0, 0.0);

    float gg = mieDir * mieDir;
    float mu = dot(shadowLightPos, pos);

    float miePhase = 3.0 * (1.0 - gg) * (1.0 + mu * mu) /
        (8.0 * 3.14159265359 * (2.0 + gg) * (1.0 + gg - 2.0 * mieDir * mu) *
        sqrt((1.0 + gg - 2.0 * mieDir * mu)));
    float rayleighPhase = 3.0 * (1.0 + mu * mu) / (16.0 * 3.14159265359);

    totalMie = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * miePhase * texture(mieTex, uv).rgb;
    totalRayleigh = mix(4.0, 40.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * rayleighPhase * texture(rayleighTex, uv).rgb;

    totalAtmosphere = totalMie + totalRayleigh;

    return clamp(1.0 - exp(-1.0 * totalAtmosphere), 0.0, 1.0);
}

vec3 getAtmosphereClouds(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 uv, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir) {
    vec3 totalAtmosphere = vec3(0.0, 0.0, 0.0);
    vec3 totalMie        = vec3(0.0, 0.0, 0.0);
    vec3 totalRayleigh   = vec3(0.0, 0.0, 0.0);

    float gg = mieDir * mieDir;
    float mu = dot(shadowLightPos, pos);

    float miePhase = 3.0 * (1.0 - gg) * (1.0 + mu * mu) /
        (8.0 * 3.14159265359 * (2.0 + gg) * (1.0 + gg - 2.0 * mieDir * mu) *
        sqrt((1.0 + gg - 2.0 * mieDir * mu)));
    float rayleighPhase = 3.0 * (1.0 + mu * mu) / (16.0 * 3.14159265359);

    totalMie = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * miePhase * texture(mieTex, uv).rgb;
    totalRayleigh = mix(4.0, 40.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * rayleighPhase * texture(rayleighTex, uv).rgb;

    totalAtmosphere = totalMie + totalRayleigh;

    vec2 clouds = getClouds(pos, sunPos, screenPos, frameTime, rainLevel);
    totalAtmosphere = mix(0.1, 10.0, smoothstep(0.0, 0.4, max(0.0, sin(sunPos.y)))) * 10.0 * totalMie * clouds.x * exp(-clouds.y * 5.0) + totalAtmosphere * exp(-clouds.x);

    return clamp(1.0 - exp(-1.0 * totalAtmosphere), 0.0, 1.0);
}

float getSun(const vec3 pos, const vec3 sunPos) {
	return smoothstep(0.05, 0.035, distance(pos, sunPos));
}

float getMoon(const vec3 pos, const vec3 moonPos) {
	return smoothstep(0.07, 0.05, distance(pos, moonPos));
}

float getStars(const vec3 pos, const float time) {
    vec3 p = floor((pos + time * 0.001) * 265.0);
    float stars = smoothstep(0.998, 1.0, hash13(p));

    return stars;
}

vec3 getSky(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 uv, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir) {
    vec3 totalSky = vec3(0.0, 0.0, 0.0);
    float daylight = mix(0.0, 1.0, max(0.0, sin(sunPos.y)));

    totalSky = getAtmosphereClouds(mieTex, rayleighTex, pos, sunPos, uv, screenPos, frameTime, rainLevel, mieDir);

    totalSky = mix(totalSky, vec3(1.0, 1.0, 1.0), getStars(pos, frameTime) * (1.0 - smoothstep(0.0, 0.4, daylight)) * (1.0 - rainLevel));
    totalSky = mix(totalSky, vec3(1.0, 1.0, 1.0), getSun(pos, sunPos) * (1.0 - rainLevel));
    totalSky = mix(totalSky, vec3(1.0, 0.95, 0.81), getMoon(pos, moonPos) * (1.0 - rainLevel));

    return totalSky;
}

vec3 getSkylightCol(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 uv, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir) {
    vec3 totalSky = vec3(0.0, 0.0, 0.0);

    totalSky = getAtmosphere(mieTex, rayleighTex, pos, sunPos, uv, screenPos, frameTime, rainLevel, mieDir);
    totalSky = mix(totalSky, vec3(getLuma(totalSky), getLuma(totalSky), getLuma(totalSky)), rainLevel);

    return totalSky;
}

#endif /* !defined MUSK_ROSE_SKYMIE_DIRECTIONLSL_INCLUDED */