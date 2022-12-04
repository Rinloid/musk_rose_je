#if !defined CLOUDS_INCLUDED
#define CLOUDS_INCLUDED 1

float fBM(vec2 x, const float amp, const float lower, const float upper, const float time, const int octaves) {
    float v = 0.0;
    float amptitude = amp;

    x += time * 0.025;

    for (int i = 0; i < octaves; i++) {
        v += amptitude * (textureNoise(x) * 0.5 + 0.5);

        /* Optimization */
        if (v >= upper) {
            break;
        } else if (v + amptitude <= lower) {
            break;
        }

        x         *= 2.0;
        x.y       -= float(i + 1) * time * 0.05;
        amptitude *= 0.5;
    }

	return smoothstep(lower, upper, v);
}

float cloudMap(const vec2 pos, const float time, const float amp, const float rain, const int oct) {
    return fBM(pos, 0.55 - abs(amp) * 0.1, mix(0.8, 0.0, rain), 0.9, time, oct);
}

float cloudMapShade(const vec2 pos, const float time, const float amp, const float rain, const int oct) {
    return fBM(pos * 0.995, 0.54 - amp * 0.1, mix(0.8, 0.0, rain), 0.875, time, oct);
}

#define ENABLE_CLOUDS
#define ENABLE_CLOUD_SHADING

/*
 ** Generate volumetric clouds with piled 2D noise.
*/
vec2 renderClouds(const vec3 pos, const vec3 camPos, const vec3 sunPos, const float brightness, const float rain, const float time) {
#   if !defined WORLD1
        const float cloudHeight = 300.0;
#   else
        const float cloudHeight = 128.0;
#   endif

#   if !defined GBUFFERS_FRAGMENT
        const float stepSize = 0.012;
        const int cloudSteps = 20;
#   else
        const float stepSize = 0.048;
        const int cloudSteps = 5;
#   endif
    const int cloudOctaves = 5;
    const int raySteps = 1;
    const float rayStepSize = 0.2;
    
    float clouds = 0.0;
    float shade = 0.0;
    float amp = -0.5;

    #ifdef ENABLE_CLOUDS
        float drawSpace = max(0.0, length(pos.xz / (pos.y * float(10))));
        if (drawSpace < 1.0 && !bool(step(pos.y, 0.0))) {
            for (int i = 0; i < cloudSteps; i++) {
                float height = 1.0 + float(i) * stepSize;
                vec2 cloudPos = pos.xz / (pos.y + camPos.y / cloudHeight) * height * cloudHeight + camPos.xz;
                cloudPos *= 0.01 + textureNoise(floor(cloudPos * 256.0)) * 0.00024;

                clouds = mix(clouds, 1.0, cloudMap(cloudPos, time, amp, rain, cloudOctaves));

                #ifdef ENABLE_CLOUD_SHADING
                    /* 
                    ** Compute self-casting shadows of clouds with
                    * a (sort of) volumetric ray marching!
                    */
                    vec3 rayStep = normalize(sunPos - pos) * rayStepSize;
                    vec3 rayPos = pos;
                    for (int i = 0; i < raySteps; i++) {
                        rayPos += rayStep;
                        float rayHeight = cloudMapShade(cloudPos, time, amp, rain, cloudOctaves);
                        
                        shade += mix(0.0, 1.0, max(0.0, rayHeight - (rayPos.y - pos.y)));
                    }

                #endif
                amp += 1.0 / float(cloudSteps);

            } shade /= float(cloudSteps);
        }

        clouds = mix(clouds, 0.0, drawSpace);
#   endif

    return vec2(clouds, shade);
}

#endif /* !defined CLOUDS_INCLUDED */