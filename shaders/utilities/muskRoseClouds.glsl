#if !defined CLOUDS_INCLUDED
#define CLOUDS_INCLUDED 1

uniform sampler2D noisetex;

const int noiseTextureResolution = 256;

float textureNoise(const vec2 pos) {
    return texture2D(noisetex, pos / float(noiseTextureResolution)).r;
}

float fBM(vec2 x, const float amp, const float lower, const float upper, const float frameTimeCounter, const int octaves) {
    float v = 0.0;
    float amptitude = amp;

    x += frameTimeCounter * 0.02;

    for (int i = 0; i < octaves; i++) {
        v += amptitude * (textureNoise(x) * 0.5 + 0.5);

        /* Optimization */
        if (v >= upper) {
            break;
        } else if (v + amptitude <= lower) {
            break;
        }

        x         *= 2.0;
        x.y       -= float(i + 1) * frameTimeCounter * 0.05;
        amptitude *= 0.5;
    }

	return smoothstep(lower, upper, v);
}

float cloudMap(const vec2 pos, const float frameTimeCounter, const float amp, const float rain, const int oct) {
    return fBM(pos, 0.55 - abs(amp) * 0.1, mix(0.8, 0.0, rain), 0.9, frameTimeCounter, oct);
}

float cloudMapShade(const vec2 pos, const float frameTimeCounter, const float amp, const float rain, const int oct) {
    return fBM(pos, 0.55 - amp * 0.1, mix(0.8, 0.0, rain), 0.85, frameTimeCounter, oct);
}

#define ENABLE_CLOUDS
#define ENABLE_CLOUD_SHADING

/*
 ** Generate volumetric clouds with piled 2D noise.
*/
vec2 renderClouds(const vec3 pos, const vec3 camPos, const vec3 sunPos, const float brightness, const float rain, const float frameTimeCounter) {
#   if !defined THE_END_SHADER
        const float cloudHeight = 256.0;
        const float stepSize = 0.02;
#   else
        const float cloudHeight = 32.0;
        const float stepSize = 0.12;
#   endif

    const int cloudSteps = 20;
    const int cloudOctaves = 5;
    const int raySteps = 1;
    const float rayStepSize = 0.2;
    
    float clouds = 0.0;
    float shade = 0.0;
    float amp = -0.5;

    float drawSpace = max(0.0, length(pos.xz / (pos.y * float(16))));
    if (drawSpace < 1.0 && !bool(step(pos.y, 0.0))) {
        for (int i = 0; i < cloudSteps; i++) {
            float height = 1.0 + float(i) * stepSize;
            vec2 cloudPos = pos.xz / (pos.y) * height * cloudHeight;
            cloudPos *= 0.005 + textureNoise(floor(cloudPos * 256.0)) * 0.00024;

            clouds = mix(clouds, 1.0, cloudMap(cloudPos, frameTimeCounter, amp, rain, cloudOctaves));

#           if defined ENABLE_CLOUD_SHADING
                /* 
                 ** Compute self-casting shadows of clouds with
                 * a (sort of) volumetric ray marching!
                */
                vec3 rayStep = normalize(sunPos - pos) * rayStepSize;
                vec3 rayPos = pos;
                for (int i = 0; i < raySteps; i++) {
                    rayPos += rayStep;
                    float rayHeight = cloudMapShade(cloudPos, frameTimeCounter, amp, rain, cloudOctaves);
                    
                    shade += mix(0.0, 1.0, max(0.0, rayHeight - (rayPos.y - pos.y)));
                }

#           endif
            amp += 1.0 / float(cloudSteps);

        } shade /= float(cloudSteps);
    }

    clouds = mix(clouds, 0.0, drawSpace);
    
    return vec2(clouds, shade);
}

#endif /* !defined CLOUDS_INCLUDED */