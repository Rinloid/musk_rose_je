#if !defined MUSK_ROSE_LIGHTS_GLSL_INCLUDED
#define MUSK_ROSE_LIGHTS_GLSL_INCLUDED

const vec3 pointlightCol = vec3(COL_POINTLIGHT_R, COL_POINTLIGHT_G, COL_POINTLIGHT_B);
// const vec3 torchlightCol = vec3(COL_TORCHLIGHT_R, COL_TORCHLIGHT_G, COL_TORCHLIGHT_B);

const vec3 skylightCol = vec3(COL_SKYLIGHT_R, COL_SKYLIGHT_G, COL_SKYLIGHT_B);
const vec3 moonlightCol = vec3(COL_MOONLIGHT_R, COL_MOONLIGHT_G, COL_MOONLIGHT_B);

vec3 getSunlightCol(const vec3 sunPos) {
    const vec3 dayCol = vec3(COL_SUNLIGHT_DAY_R, COL_SUNLIGHT_DAY_G, COL_SUNLIGHT_DAY_B);
    const vec3 setCol = vec3(COL_SUNLIGHT_SET_R, COL_SUNLIGHT_SET_G, COL_SUNLIGHT_SET_B);

    return mix(setCol, dayCol, smoothstep(0.0, 0.4, sin(sunPos.y)));
}

vec4 getAmbientLight(const vec3 sunPos, const vec2 uv1, const float occlusion) {
    vec4 totalAmbientLight = vec4(0.0, 0.0, 0.0, 0.0);

    totalAmbientLight.rgb = mix(moonlightCol * 0.4, getSunlightCol(sunPos) * smoothstep(0.0, 0.4, sin(sunPos.y)), max(0.0, sin(sunPos.y)));
    totalAmbientLight.rgb = mix(totalAmbientLight.rgb, skylightCol * mix(0.2, 1.0, max(0.0, sin(sunPos.y))), 0.5);
    totalAmbientLight.rgb = mix(mix(vec3(UNLIT_AREA_BRIGHTNESS, UNLIT_AREA_BRIGHTNESS, UNLIT_AREA_BRIGHTNESS), vec3(1.0, 1.0, 1.0), nightVision), totalAmbientLight.rgb, uv1.y);
    totalAmbientLight.rgb = mix(totalAmbientLight.rgb, pointlightCol, uv1.x * uv1.x * uv1.x * uv1.x * uv1.x);
    totalAmbientLight.a = float(AMBIENTLIGHT_INTENSITY) * (1.0 - occlusion);

    return totalAmbientLight;
}

vec4 getSkylight(const vec3 sunPos, const vec2 uv1) {
    vec4 totalSkyLight = vec4(0.0, 0.0, 0.0, 0.0);

    if (uv1.y > 0.0) {
        totalSkyLight.rgb = skylightCol * mix(0.2, 1.0, max(0.0, sin(sunPos.y)));
        totalSkyLight.a = float(SKYLIGHT_INTENSITY) * uv1.y;
        totalSkyLight.a *= (1.0 - rainStrength) * RAIN_CUTOFF;
    }

    return totalSkyLight;
}

vec4 getSunlight(const vec4 shadows, const vec3 sunPos) {
    vec4 totalSunLight = vec4(0.0, 0.0, 0.0, 0.0);

    if (shadows.a != 1.0 && bool(step(0.0, sin(sunPos.y)))) {
        vec3 sunlightCol = getSunlightCol(sunPos);

        totalSunLight.rgb = mix(sunlightCol, shadows.rgb, shadows.a);
        totalSunLight.a = float(SUNLIGHT_INTENSITY) * smoothstep(0.0, 0.4, sin(sunPos.y)) * (1.0 - shadows.a);
        totalSunLight.a *= (1.0 - rainStrength) * RAIN_CUTOFF;
    }

    return totalSunLight;
}

vec4 getMoonlight(const vec4 shadows, const vec3 moonPos) {
    vec4 totalMoonLight = vec4(0.0, 0.0, 0.0, 0.0);

    if (shadows.a != 1.0 && bool(step(0.0, sin(moonPos.y)))) {
        totalMoonLight.rgb = mix(moonlightCol, shadows.rgb, shadows.a);
        totalMoonLight.a = float(MOONLIGHT_INTENSITY) * smoothstep(0.0, 0.4, sin(moonPos.y)) * (1.0 - shadows.a);
        totalMoonLight.a *= (1.0 - rainStrength) * RAIN_CUTOFF;
    }

    return totalMoonLight;
}

vec4 getPointlight(const vec2 uv1) {
    vec4 totalPointLight = vec4(0.0, 0.0, 0.0, 0.0);

    if (uv1.x > 0.0) {
        totalPointLight.rgb = pointlightCol;
        totalPointLight.a = float(POINTLIGHT_INTENSITY) * uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
    }

    return totalPointLight;
}

vec3 fresnelSchlick(const vec3 H, const vec3 N, const vec3 reflectance) {
    float cosTheta = clamp(1.0 - max(0.0, dot(H, N)), 0.0, 1.0);

    return clamp(reflectance + (1.0 - reflectance) * cosTheta * cosTheta * cosTheta * cosTheta * cosTheta, 0.0, 1.0);
}

#endif /* MUSK_ROSE_LIGHTS_GLSL_INCLUDED */