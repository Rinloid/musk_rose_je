#if !defined MUSK_ROSE_CLOUDS_GLSL_INCLUDED
#define MUSK_ROSE_CLOUDS_GLSL_INCLUDED

#include "/utils/musk_rose_noise.glsl"

float getFluffyClouds(const vec2 pos, const float amp, const float lower, const float upper, const float time, const float rainLevel, const int octaves) {
    float v = 0.0;
    float amptitude = amp;
	vec2 x = pos * 0.05;

    x += time * 0.025;

    for (int i = 0; i < octaves; i++) {
        v += amptitude * (getCloudNoise(x, rainLevel) * 0.5 + 0.5);

        if (v >= upper) {
            break;
        } else if (v + amptitude <= lower) {
            break;
        }

        x         *= 2.0;
        x.y       -= float(i + 1) * time * 0.05;
        amptitude *= 0.5;
    }

	return smoothstep(mix(lower, 0.0, rainLevel), upper, v);
}

float getBlockyClouds(const vec2 pos, const float time, const float rainLevel) {
    vec2 p = pos * 0.5;
    p += time * 0.02;
    float body = hash12(floor(p));
    body = body > mix(0.7, 0.0, rainLevel) ? 1.0 : 0.0;

    return body;
}

// #define ENABLE_BLOCKY_CLOUDS

vec3 getClouds(const vec3 pos, const vec3 relPos, const vec3 cameraPos, const vec3 lightPos, const float time, const float rainLevel) {
#   if !defined DEFERRED_FSH
        #ifdef ENABLE_BLOCKY_CLOUDS
            const int cloudSteps = 16;
            const float cloudStepSize = 0.012;
            const int raySteps = 8;
            const float rayStepSize = 0.16;
            const float cloudHeight = 256.0;
        #else
            const int cloudSteps = 16;
            const float cloudStepSize = 0.024;
            const int raySteps = 3;
            const float rayStepSize = 0.08;
            const float cloudHeight = 224.0;
        #endif
#   else
        #ifdef ENABLE_BLOCKY_CLOUDS
            const int cloudSteps = 32;
            const float cloudStepSize = 0.006;
            const int raySteps = 16;
            const float rayStepSize = 0.08;
            const float cloudHeight = 256.0;
        #else
            const int cloudSteps = 32;
            const float cloudStepSize = 0.012;
            const int raySteps = 6;
            const float rayStepSize = 0.04;
            const float cloudHeight = 224.0;
    #endif
#   endif

    float clouds = 0.0;
    float shade  = 0.0;
    float highlight = 0.0;

    float amp = 0.5;

    float drawSpace = max(0.0, length(relPos.xz / (relPos.y * float(8))));
    if (drawSpace < 1.0 && !bool(step(relPos.y, 0.0))) {
        for (int i = 0; i < cloudSteps; i++) {
            float height = 1.0 + float(i) * cloudStepSize;
            vec3 camPos = cameraPos;
            camPos.y = cameraPosition.y > cloudHeight ? cloudHeight : camPos.y;
            camPos.y /= height;
            vec3 p = vec3(pos.xz * 0.01 * ((cloudHeight - camPos.y) / pos.y * height), (cloudHeight - camPos.y)).xzy + hash13(floor(pos * 2048.0)) * 0.04;
            #ifdef ENABLE_BLOCKY_CLOUDS
                clouds += getBlockyClouds(p.xz + camPos.xz * 0.01, time, rainLevel);
            #else
                clouds += getFluffyClouds(p.xz + camPos.xz * 0.01, amp, 0.54, 0.56, time * 0.1, rainLevel, 3) * 1.2;
            #endif

            if (clouds > 0.0) {
                vec3 rayPos = (vec3(pos.xz * 0.01 * ((cloudHeight - camPos.y) / pos.y * height), (cloudHeight - camPos.y)).xzy - lightPos * rayStepSize);
                float ray = 0.0;
                for (int j = 0; j < raySteps; j++) {
                    #ifdef ENABLE_BLOCKY_CLOUDS
                        ray += getBlockyClouds(rayPos.xz + camPos.xz * 0.01, time, rainLevel) * 0.6;
                    #else
                        ray += getFluffyClouds(rayPos.xz + camPos.xz * 0.01 * 0.95, amp, 0.54, 0.6, time * 0.1, rainLevel, 3) * 0.75;
                    #endif
                    rayPos += lightPos * rayStepSize;
                } ray /= float(raySteps);
                shade += ray;
                highlight += ray * ray * ray * ray * ray * ray;
            }
            amp -= 0.2 / float(cloudSteps);
        } clouds /= float(cloudSteps);
          shade /= float(cloudSteps);
          highlight /= float(cloudSteps);

        clouds = mix(clouds, 0.0, drawSpace);
    }

    return vec3(clouds, shade, 1.0 - highlight);
}

#endif /* !defined MUSK_ROSE_CLOUDS_GLSL_INCLUDED */