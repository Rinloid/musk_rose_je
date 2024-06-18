#if !defined MUSK_ROSE_POM_GLSL_INCLUDED
#define MUSK_ROSE_POM_GLSL_INCLUDED

mat3 getTBNMatrixUV(vec3 pos, vec2 uv) {
    vec2 dxUV = normalize(dFdx(uv));
    vec2 dyUV = normalize(dFdy(uv));
    vec3 dxPos = normalize(dFdx(pos));
    vec3 dyPos = normalize(dFdy(pos));

    vec3 N = normalize(cross(dFdx(pos), dFdy(pos)));
    vec3 B = (dyUV.x * dxPos - dxUV.x * dyPos) / (dxUV.y * dyUV.x - dxUV.x * dyUV.y);
    vec3 T = normalize(cross(N, B));

    return transpose(mat3(dot((dyPos - dyUV.y * B) / dyUV.x, T) > 0.0 ? T : -T, B, N));
}

float getHeightmap(vec2 uv) {
    return texture(normals, uv).a;
}

float getParallaxUVAndShadows(in vec3 pos, in vec3 sunPos, inout vec2 uv) {
    const int textureResolution = 16;
    const int parallaxSamples = 12;
    const float parallaxDepth = 0.3;

    mat3 tbnMatrix = getTBNMatrixUV(pos, uv);

    vec3 parallaxUV = vec3(uv, 0.0); 
    vec3 tanPos = normalize(tbnMatrix * normalize(pos));
    tanPos /= tanPos.z;
    tanPos.xy /= atlasSize.xy / textureResolution;

    if (getHeightmap(parallaxUV.xy) > 0.0) {
        for (int i = 0; i < parallaxSamples; i++) {
            if (1.0 + parallaxUV.z > getHeightmap(parallaxUV.xy)) {
                parallaxUV -= tanPos / (textureResolution * parallaxSamples) * parallaxDepth;
            }
        }
    uv = parallaxUV.xy;
    }

    vec3 parallaxUVShadows = parallaxUV; 
    vec3 tanSunPos = normalize(tbnMatrix * sunPos);
    tanSunPos.xy /= atlasSize.xy / textureResolution;

    float shadows = 0.0;

    for (int j = 0; j < parallaxSamples; j++) {
        if (parallaxUVShadows.z < 0.0) {
            parallaxUVShadows += tanSunPos / (textureResolution * parallaxSamples) * parallaxDepth;
            if (1.0 + parallaxUVShadows.z < getHeightmap(parallaxUVShadows.xy)) {
                shadows = 1.0;
            }
        }
    }

    return shadows;
}

#endif /* !defined MUSK_ROSE_POM_GLSL_INCLUDED */