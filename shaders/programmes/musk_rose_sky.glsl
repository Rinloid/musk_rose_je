#if !defined MUSK_ROSE_SKY_GLSL_INCLUDED
#define MUSK_ROSE_SKY_GLSL_INCLUDED

#include "utils/musk_rose_filter.glsl"

float hashTex(const vec2 pos) {
    return texture(colortex11, pos / float(HASH_TEXTURE_RESOLUTION)).r;
}

float getCloudMap(const vec2 pos) {
	return texture(colortex12, pos / float(VORONOI_TEXTURE_RESOLUTION)).r;
}

#ifdef ENABLE_SHADER_CLOUDS
    float getFluffyClouds(const vec2 pos, const float amp, const float lower, const float upper, const int octaves) {
        float v = 0.0;
        float amptitude = amp;
        vec2 x = pos * 4.0;

        x += frameTimeCounter * WIND_POWER * 0.075;

        for (int i = 0; i < octaves; i++) {
            v += amptitude * (getCloudMap(x) * 0.5 + 0.5);

            if (v >= upper) {
                break;
            } else if (v + amptitude <= lower) {
                break;
            }

            x         *= 2.0;
            x.y       -= float(i + 1) * frameTimeCounter * WIND_POWER * 0.25;
            amptitude *= 0.5;
        }

        return smoothstep(lower, upper, v);
    }

    float getBlockyClouds(const vec2 pos) {
        vec2 p = pos * 0.5;
        p += frameTimeCounter * WIND_POWER * 0.015;
        float body = hash12(floor(p));
        body = body > mix(0.8, 0.3, rainStrength) ? 1.0 : 0.0;

        return body;
    }

    vec2 getClouds(const vec3 pos, const vec3 sunPos) {
#      if defined CLOUDS_QUALITY_LOW
            #ifdef ENABLE_BLOCKY_CLOUDS
                const int cloudSteps = 16;
                const float cloudStepSize = 0.012;
                const int raySteps = 8;
                const float rayStepSize = 0.04;
                const float cloudShadeMult = 0.2;
            #else
                const int cloudSteps = 12;
                const float cloudStepSize = 0.064;
                const int raySteps = 4;
                const float rayStepSize = 0.08;
                const float cloudShadeMult = 4.0;
            #endif
#      else
            #ifdef ENABLE_BLOCKY_CLOUDS
                const int cloudSteps = 32;
                const float cloudStepSize = 0.006;
                const int raySteps = 16;
                const float rayStepSize = 0.02;
                const float cloudShadeMult = 0.1;
            #else
                const int cloudSteps = 24;
                const float cloudStepSize = 0.032;
                const int raySteps = 8;
                const float rayStepSize = 0.04;
                const float cloudShadeMult = 2.0;
        #endif
#      endif
        const float cloudHeight = 256.0;

        vec2 totalClouds = vec2(0.0, 0.0);
        float clouds = 0.0;
        float shade  = 0.0;
        float highlight = 0.0;

        float amp = mix(0.485, 0.52, rainStrength);

        float drawSpace = max(0.0, length(pos.xz / (pos.y * float(10))));
        if (drawSpace < 1.0 && !bool(step(pos.y, 0.0))) {
            for (int i = 0; i < cloudSteps; i++) {
                float height = 1.0 + float(i) * cloudStepSize;
                vec3 p = pos.xyz / pos.y * height;
                #ifdef ENABLE_BLOCKY_CLOUDS
                    clouds += getBlockyClouds(p.xz * 4.0);
                #else
                    clouds += getFluffyClouds(p.xz * 4.0, abs(amp), 0.7, 0.75, 5);
                #endif

                if (clouds > 0.0) {
                    vec3 rayPos = (pos.xyz / pos.y * height) - sunPos * rayStepSize;
                    float ray = 0.0;
                    for (int j = 0; j < raySteps; j++) {
                        #ifdef ENABLE_BLOCKY_CLOUDS
                            ray += getBlockyClouds(rayPos.xz * 3.7) * cloudShadeMult;
                        #else
                            ray += getFluffyClouds(rayPos.xz * 4.0, abs(amp), 0.7, 1.0, 5) * cloudShadeMult;
                        #endif
                        rayPos += sunPos * rayStepSize;
                    } ray;
                    shade += ray;
                }
                amp -= 0.12 / float(cloudSteps);
            } clouds /= float(cloudSteps);
            shade /= float(cloudSteps);

            clouds = mix(clouds, 0.0, drawSpace);
        }

        totalClouds = vec2(clouds, shade);

        return totalClouds;
    }
#endif

float getMiePhase(const vec3 pos, const vec3 shadowLightPos, const float mieDir) {
    float gg = mieDir * mieDir;
    float mu = dot(shadowLightPos, pos);

    return 3.0 * (1.0 - gg) * (1.0 + mu * mu) /
        (8.0 * 3.14159265359 * (2.0 + gg) * (1.0 + gg - 2.0 * mieDir * mu) *
        sqrt((1.0 + gg - 2.0 * mieDir * mu)));
}

float getRayleighPhase(const vec3 pos, const vec3 shadowLightPos) {
    float mu = dot(shadowLightPos, pos);

    return 3.0 * (1.0 + mu * mu) / (16.0 * 3.14159265359);
}

vec3 getAtmosphere(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec3 shadowLightPos, const vec2 uv) {
	const float mieDir = 0.75;

    vec3 totalAtmosphere = vec3(0.0, 0.0, 0.0);
    vec3 totalMie        = vec3(0.0, 0.0, 0.0);
    vec3 totalRayleigh   = vec3(0.0, 0.0, 0.0);

    float miePhase = getMiePhase(pos, shadowLightPos, mieDir);
    float rayleighPhase = getRayleighPhase(pos, shadowLightPos);

    #ifdef ENABLE_SUN
        totalMie = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * miePhase * texture(mieTex, uv).rgb * max(0.5, (1.0 - rainStrength));
    #endif
    totalRayleigh = mix(4.0, 40.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * rayleighPhase * texture(rayleighTex, uv).rgb * max(0.5, (1.0 - rainStrength));

    totalAtmosphere = totalMie + totalRayleigh;
    totalAtmosphere = mix(totalAtmosphere, vec3(getLuma(totalAtmosphere), getLuma(totalAtmosphere), getLuma(totalAtmosphere)), rainStrength);

    return clamp(1.0 - exp(-1.0 * totalAtmosphere), 0.0, 1.0);
}

vec3 getAtmosphereClouds(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec3 shadowLightPos, const vec2 uv) {
	const float mieDir = 0.75;

    vec3 totalAtmosphere = vec3(0.0, 0.0, 0.0);
    vec3 totalMie        = vec3(0.0, 0.0, 0.0);
    vec3 totalRayleigh   = vec3(0.0, 0.0, 0.0);

    float miePhase = getMiePhase(pos, shadowLightPos, mieDir);
    float rayleighPhase = getRayleighPhase(pos, shadowLightPos);

    #ifdef ENABLE_SUN
        totalMie = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * miePhase * texture(mieTex, uv).rgb * max(0.5, (1.0 - rainStrength));
    #endif
    totalRayleigh = mix(4.0, 40.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * rayleighPhase * texture(rayleighTex, uv).rgb * max(0.5, (1.0 - rainStrength));

    totalAtmosphere = totalMie + totalRayleigh;
    totalAtmosphere = mix(totalAtmosphere, vec3(getLuma(totalAtmosphere), getLuma(totalAtmosphere), getLuma(totalAtmosphere)), rainStrength);

    #ifdef ENABLE_SHADER_CLOUDS
        vec2 clouds = getClouds(pos, sunPos);
        vec3 cloudMie = mix(0.2, 2.0, smoothstep(0.0, 0.2, max(0.0, sin(sunPos.y)))) * getMiePhase(pos * 0.2, shadowLightPos, mieDir) * pow(texture(mieTex, uv).rgb, vec3(1.2)) * max(0.5, (1.0 - rainStrength));
        vec3 totalClouds = mix(5.0, 10.0, smoothstep(0.0, 0.4, max(0.0, sin(sunPos.y)))) * 100.0 * cloudMie * clouds.x * exp(-clouds.y);

        totalAtmosphere *= exp(-clouds.x);
        totalAtmosphere += toneMapReinhard(totalClouds);
    #endif

    return clamp(1.0 - exp(-1.0 * totalAtmosphere), 0.0, 1.0);
}

float getSun(const vec3 pos, const vec3 sunPos) {
	#ifdef ENABLE_SUN
        return smoothstep(0.05, 0.00, distance(pos, sunPos));
    #else
        return 0.0;
    #endif
}

float getMoonPhase(const int phase) {
	// moonPhase variable: [0, 1, 2, 3, 4, 5, 6, 7]
	// Moon in MC:         [4, 5, 6, 7, 0, 1, 2, 3]
	// 0 = new moon; 7 = full moon.
	int correctedPhase = 0 <= phase && phase < 5 ? phase + 4 : phase;

	// [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
	return correctedPhase * 0.25 * 3.14159265359;
}

float diffuseSphere(const vec3 spherePos, const vec3 lightPos, const float radius) {
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
    #ifdef ENABLE_MOON
        float moon = smoothstep(0.0, 0.7, diffuseSphere(moonPosition, vec3(sin(moonPhase), 0.0, -cos(moonPhase)), moonScale));
        return vec4(mix(vec3(0.2, 0.15, 0.11), vec3(1.0, 0.95, 0.81), moon), diffuseSphere(moonPosition, vec3(0.0, 0.0, 1.0), moonScale));
    #else
        return vec4(0.0, 0.0, 0.0, 0.0);
    #endif
}

float getStars(const vec3 pos) {
    #ifdef ENABLE_STARS
        vec3 p = floor((pos + frameTimeCounter * 0.001) * 265.0);
        float stars = smoothstep(0.998, 1.0, hash13(p));
        return stars;
    #else
        return 0.0;
    #endif
}

vec3 getSky(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec3 shadowLightPos, const vec2 uv) {
    vec3 totalSky = vec3(0.0, 0.0, 0.0);
    vec4 moon = getMoon(cross(pos, moonPos), getMoonPhase(moonPhase), 0.05);
#   if defined WORLD1
        totalSky = getAtmosphere(mieTex, rayleighTex, pos, sunPos, shadowLightPos, uv);
#   else
        totalSky = getAtmosphereClouds(mieTex, rayleighTex, pos, sunPos, shadowLightPos, uv);
#   endif
    totalSky = mix(totalSky, vec3(1.0, 1.0, 1.0), getStars(pos)
#       if !defined WORLD1
             * (1.0 - smoothstep(0.0, 0.4, max(0.0, sin(sunPos.y))))
#       else
             * step(-pos.y, 0.0)
#       endif
     * (1.0 - rainStrength));
    totalSky = mix(totalSky, vec3(1.0, 1.0, 1.0), getSun(pos, sunPos) * (1.0 - rainStrength));
#   if !defined WORLD1
        totalSky = mix(totalSky, moon.rgb, moon.a * smoothstep(0.07, 0.05, distance(pos, -sunPos)) * (1.0 - rainStrength));
#   endif

    return totalSky;
}

#endif /* !defined MUSK_ROSE_SKY_GLSL_INCLUDED */