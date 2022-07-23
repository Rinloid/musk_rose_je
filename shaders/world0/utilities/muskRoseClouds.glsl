uniform sampler2D noisetex;

const int noiseTextureResolution = 256;

float textureNoise(const vec2 pos) {
    return texture2D(noisetex, pos / float(noiseTextureResolution)).r;
}

float fBM(vec2 x, const float amp, const float lower, const float upper, const float time, const int octaves) {
    float v = 0.0;
    float amptitude = amp;

    x += time * 0.02;

    for (int i = 0; i < octaves; i++) {
        v += amptitude * (textureNoise(x) * 0.5 + 0.5);

        if (v >= upper) {
            break;
        } else if (v + amptitude <= lower) {
            break;
        }

        x         *= 2.0;
        x.y       -= float(i + 1) * time * 0.04;
        amptitude *= 0.5;
    }

	return smoothstep(lower, upper, v);
}

float cloudMap(const vec2 pos, const float time, const float amp, const float rain, const int oct) {
    return fBM(pos, 0.55 - amp * 0.1, mix(0.8, 0.0, rain), 0.825, time, oct);
}

float cloudMapShade(const vec2 pos, const float time, const float amp, const float rain, const int oct) {
    return fBM(pos * 0.9, 0.55 - amp * 0.1, mix(0.75, 0.0, rain), 1.0, time, oct);
}

vec4 renderClouds(const vec3 pos, const vec3 camPos, const vec3 sunPos, const float brightness, const float rain, const float time) {
    const vec3 cloudCol = vec3(1.0, 0.99, 0.97);
    const float cloudHeight = 256.0;
    const int cloudOctaves = 6;
    const int cloudSteps = 40;
    const float stepSize = 0.01;
    const int raySteps = 2;
    const float rayStepSize = 0.18;
    
    vec4 clouds = vec4(cloudCol * brightness, 0.0);
    float amp = 0.0;

    float drawSpace = max(0.0, length(pos.xz / (pos.y * float(16))));
    if (drawSpace < 1.0 && !bool(step(pos.y, 0.0))) {
        for (int i = 0; i < cloudSteps; i++) {
            float height = 1.0 + float(i) * stepSize;
            vec2 cloudPos = pos.xz / (pos.y) * height * cloudHeight;
            cloudPos *= 0.005;

            clouds.a += cloudMap(cloudPos, time, amp, rain, cloudOctaves);

            vec3 rayStep = normalize(sunPos - pos) * rayStepSize;
            vec3 rayPos = pos;
            float inside = 0.0;
            for (int i = 0; i < raySteps; i++) {
                rayPos += rayStep;
                float rayHeight = cloudMapShade(cloudPos, time, amp, rain, cloudOctaves);
                
                inside += max(0.0, rayHeight - (rayPos.y - pos.y));
            } inside /= float(raySteps);

            amp += 1.0 / float(cloudSteps);

            clouds.rgb = mix(clouds.rgb + 0.2 / float(cloudSteps) * brightness, max(vec3(0.0), clouds.rgb - 0.3 / float(cloudSteps) * brightness), inside);
        } clouds.a /= float(cloudSteps);
    }

    clouds.a = mix(clouds.a, 0.0, drawSpace);
    
    // clouds.a = clouds.a > 0.0 ? 1.0 : 0.0;
    // clouds.a = smoothstep(0.0, 0.5, clouds.a);
    // clouds.a = pow(clouds.a, 1.2);


    return clouds;
}