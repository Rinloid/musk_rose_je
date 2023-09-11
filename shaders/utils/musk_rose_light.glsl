#if !defined MUSK_ROSE_LIGHT_GLSL_INCLUDED
#define MUSK_ROSE_LIGHT_GLSL_INCLUDED

vec3 brighten(const vec3 col) {
    float rgbMax = max(col.r, max(col.g, col.b));
    float delta  = 1.0 - rgbMax;

    return col + delta;
}

#define pointlightCol vec3(1.00, 0.66, 0.28)
#define moonlightCol vec3(1.0, 0.98, 0.8)

vec3 getSunlightCol(const float daylight) {
    const vec3 setCol = vec3(1.00, 0.36, 0.02);
    const vec3 dayCol = vec3(1.00, 0.77, 0.70);

    return mix(setCol, dayCol, max(0.75, daylight));
}

#include "/utils/musk_rose_sky.glsl"

vec3 getAmbientLightCol(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 atmoUV, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir, const float outdoor, const float pointLightLevel) {
    vec3 totalAmbientLightCol = vec3(0.0, 0.0, 0.0);

    totalAmbientLightCol = mix(mix(vec3(1.0, 1.0, 1.0), pointlightCol, pointLightLevel), mix(moonlightCol, mix(getSunlightCol(max(0.0, sin(sunPos.y))), getSkylightCol(mieTex, rayleighTex, pos, sunPos, atmoUV, screenPos, frameTime, rainLevel, mieDir), 0.5), max(0.0, sin(sunPos.y))), outdoor);

    return totalAmbientLightCol;
}

#define AMBIENTLIGHT_INTENSITY 10.0
#define POINTLIGHT_INTENSITY 100.0
#define SUNLIGHT_INTENSITY 70.0
#define SKYLIGHT_INTENSITY 40.0
#define MOONLIGHT_INTENSITY 20.0

#define RAIN_CUTOFF 0.5
#define SHADOW_CUTOFF 0.35

vec3 getAmbientLight(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 atmoUV, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir, const float outdoor, const float pointLightLevel) {
    vec3 totalAmbientLight = vec3(0.0, 0.0, 0.0);
    
    float intensity = AMBIENTLIGHT_INTENSITY * mix(max(0.25, outdoor * 0.5), max(0.5, sin(sunPos.y)), outdoor);
    totalAmbientLight = intensity * getAmbientLightCol(mieTex, rayleighTex, pos, sunPos, atmoUV, screenPos, frameTime, rainLevel, mieDir, outdoor, pointLightLevel);

    return totalAmbientLight;
}

vec3 getSunlight(const float daylight, const vec4 directionalShadowCol, const float rainLevel) {
    vec3 totalSunLight = vec3(0.0, 0.0, 0.0);

    float intensity = SUNLIGHT_INTENSITY * daylight;
    intensity *= mix(1.0, RAIN_CUTOFF, rainLevel);

    totalSunLight = intensity * getSunlightCol(daylight);
    totalSunLight = mix(totalSunLight, vec3(0.0, 0.0, 0.0), directionalShadowCol.a);
    totalSunLight += intensity * directionalShadowCol.rgb * SHADOW_CUTOFF;

    return totalSunLight;
}

vec3 getMoonlight(const float moonHeight, const vec4 directionalShadowCol, const float rainLevel) {
    vec3 totalMoonLight = vec3(0.0, 0.0, 0.0);

    float intensity = MOONLIGHT_INTENSITY * moonHeight;
    intensity *= mix(1.0, RAIN_CUTOFF, rainLevel);

    totalMoonLight = intensity * moonlightCol;
    totalMoonLight = mix(totalMoonLight, vec3(0.0, 0.0, 0.0), directionalShadowCol.a);
    totalMoonLight += intensity * directionalShadowCol.rgb * SHADOW_CUTOFF;

    return totalMoonLight;
}

vec3 getSkylight(const sampler2D mieTex, const sampler2D rayleighTex, const vec3 pos, const vec3 sunPos, const vec2 atmoUV, const vec2 screenPos, const float frameTime, const float rainLevel, const float mieDir, const float outdoor) {
    vec3 totalSkyLight = vec3(0.0, 0.0, 0.0);

    float intensity = SKYLIGHT_INTENSITY;
    intensity *= mix(1.0, RAIN_CUTOFF, rainLevel);

    totalSkyLight = intensity * getSkylightCol(mieTex, rayleighTex, pos, sunPos, atmoUV, screenPos, frameTime, rainLevel, mieDir);
    totalSkyLight *= outdoor;

    return totalSkyLight;
}

vec3 getPointLight(const float pointLightLevel, const float sunLevel, const float daylight, const float rainLevel) {
    vec3 totalPointLight = vec3(0.0, 0.0, 0.0);

    float intensity = POINTLIGHT_INTENSITY * pointLightLevel;
    intensity *= mix(mix(1.0, 0.0, smoothstep(0.0, 1.0, sunLevel * daylight)), RAIN_CUTOFF, rainLevel);

    totalPointLight = intensity * pointlightCol;

    return totalPointLight;
}

vec3 fresnelSchlick(const vec3 H, const vec3 N, const vec3 reflectance) {
    float cosTheta = clamp(1.0 - max(0.0, dot(H, N)), 0.0, 1.0);

    return clamp(reflectance + (1.0 - reflectance) * cosTheta * cosTheta * cosTheta * cosTheta * cosTheta, 0.0, 1.0);
}

vec3 getPBRSpecular(const vec3 V, const vec3 L, const vec3 N, const float R, const vec3 reflectance) {
    vec3  H = normalize(V + L);
    float D = (R * R)
            / (3.14159265359 * (max(0.0, dot(H, N)) * max(0.0, dot(H, N)) * (R * R - 1.0) + 1.0) * (max(0.0, dot(H, N)) * max(0.0, dot(H, N)) * (R * R - 1.0) + 1.0));
    float G = ((max(0.0, dot(V, N))) / (max(0.0, dot(V, N)) + ((R + 1.0) * (R + 1.0)) * 0.125))
            * ((max(0.0, dot(L, N))) / (max(0.0, dot(L, N)) + ((R + 1.0) * (R + 1.0)) * 0.125));
    vec3  F = fresnelSchlick(H, V, reflectance);

    return vec3(clamp((D * G * F) / max(0.001, 4.0 * max(dot(N, V), 0.0) * max(dot(L, N), 0.0)), 0.0, 1.0));
}

#endif /* !defined MUSK_ROSE_LIGHT_GLSL_INCLUDED */