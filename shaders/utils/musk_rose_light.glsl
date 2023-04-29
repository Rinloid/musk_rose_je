#if !defined MUSK_ROSE_LIGHT_GLSL_INCLUDED
#define MUSK_ROSE_LIGHT_GLSL_INCLUDED

#define RAIN_CUTOFF 0.3

const vec3 torchlightCol = vec3(1.00, 0.66, 0.28);
const vec3 moonlightCol  = vec3(0.20, 0.40, 1.00);

#include "/utils/musk_rose_sky.glsl"

vec3 brighten(const vec3 col) {
    float rgbMax = max(col.r, max(col.g, col.b));
    float delta  = 1.0 - rgbMax;

    return col + delta;
}

vec3 getSkyLightCol(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float daylight, const float rainLevel) {
	vec3 sky = getAtmosphere(pos, sunPos, skyCol, vanillaSkyCol, vanillaFogCol, mix(0.5, 2.0, smoothstep(0.0, 0.1, daylight)));
	sky = toneMapReinhard(sky);

	sky = mix(sky, vec3(getLuma(sky)), rainLevel);

	return sky;
}

vec3 getSunlightCol(const float daylight) {
    const vec3 setCol = vec3(1.00, 0.36, 0.02);
    const vec3 dayCol = vec3(1.00, 0.87, 0.80);

    return mix(dayCol, setCol, min(smoothstep(0.0, 0.2, daylight), smoothstep(0.4, 0.2, daylight)));
}

vec3 getAmbientLightCol(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float torchLevel, const float indoor, const float shadowLightLevel, const float daylight, const float rainLevel) {
    vec3 dayCol     = mix(getSkyLightCol(pos, sunPos, skyCol, vanillaSkyCol, vanillaFogCol, daylight, rainLevel), getSunlightCol(daylight), 0.5);
    vec3 nightCol   = moonlightCol;

    vec3 outsideCol = mix(nightCol, dayCol, smoothstep(0.0, 0.2, daylight));
    vec3 insideCol  = mix(vec3(0.0), torchlightCol, torchLevel);

    vec3 result     = mix(insideCol, outsideCol, indoor * shadowLightLevel);

    return brighten(result);
}

vec3 getAmbientLight(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float torchLevel, const float indoor, const float shadowLightLevel, const float daylight, const float rainLevel) {
    const float baseIntensity = 40.0;

    vec3 col = getAmbientLightCol(pos, sunPos, skyCol, vanillaSkyCol, vanillaFogCol, torchLevel, indoor, shadowLightLevel, daylight, rainLevel);
    float intensity = mix(0.0, mix(mix(0.05, 0.35, daylight), mix(0.05, 1.0, daylight), shadowLightLevel), indoor);

    vec3 result = col * baseIntensity * intensity;

    return result;
}

vec3 getTorchLight(const float torchLevel, const float indoor, const float shadowLightLevel, const float daylight) {
    const float baseIntensity = 130.0;

    float intensity = baseIntensity * torchLevel;

    return torchlightCol * intensity;
}

vec3 getSunlight(const float indoor, const float shadowLightLevel, const float daylight, const float rainLevel) {
    const float baseIntensity = 40.0;

    float intensity = baseIntensity * mix(0.0, mix(1.0, 5.0, min(smoothstep(0.0, 0.2, daylight), smoothstep(0.4, 0.2, daylight))), daylight) * indoor * shadowLightLevel;
    intensity = mix(intensity, RAIN_CUTOFF, rainLevel);

    return getSunlightCol(daylight) * intensity;
}

vec3 getSkyLight(const vec3 pos, const vec3 sunPos, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol, const float rainLevel, const float indoor, const float shadowLightLevel, const float daylight) {
    const float baseIntensity = 30.0;

    float intensity = baseIntensity * daylight * indoor * shadowLightLevel;
    intensity = mix(intensity, RAIN_CUTOFF, rainLevel);
    
    return getSkyLightCol(pos, sunPos, skyCol, vanillaSkyCol, vanillaFogCol, daylight, rainLevel) * intensity;
}

vec3 getMoonlight(const float indoor, const float shadowLightLevel, const float daylight, const float rainLevel) {
    const float baseIntensity = 20.0;

    float intensity = baseIntensity * (1.0 - mix(0.0, 0.2, daylight)) * indoor * shadowLightLevel;
    intensity = mix(intensity, RAIN_CUTOFF, rainLevel);

    return moonlightCol * intensity;
}

vec3 fresnelSchlick(const vec3 H, const vec3 N, const vec3 F0) {
	float cosTheta = clamp(1.0 - max(0.0, dot(H, N)), 0.0, 1.0);

    return F0 + (1.0 - F0) * cosTheta * cosTheta * cosTheta * cosTheta * cosTheta;
}

// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
vec3 getEnvironmentBRDF(const vec3 H, const vec3 N, const float R, const vec3 F0) {
	const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
	const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

	vec4 r = R * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * max(0.0, dot(H, N)))) * r.x + r.y;
	vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;

	return F0 * AB.x + AB.y;
}

vec3 getPBRSpecular(const vec3 N, const vec3 V, const vec3 L, const float R, const float F0) {
	vec3  H = normalize(V + L);
    float D = (R * R)
			/ (3.14159265359 * (max(0.0, dot(H, N)) * max(0.0, dot(H, N)) * (R * R - 1.0) + 1.0) * (max(0.0, dot(H, N)) * max(0.0, dot(H, N)) * (R * R - 1.0) + 1.0));
    float G = ((max(0.0, dot(V, N))) / (max(0.0, dot(V, N)) + ((R + 1.0) * (R + 1.0)) * 0.125))
			* ((max(0.0, dot(L, N))) / (max(0.0, dot(L, N)) + ((R + 1.0) * (R + 1.0)) * 0.125));
    vec3  F = fresnelSchlick(H, V, vec3(F0));

	return clamp((D * G * F) / max(0.01, 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)), 0.0, 1.0);
}

vec3 getTotalLight(const vec4 albedo, const vec4 shadows, const vec3 skyCol, const vec3 vanillaSkyCol, const vec3 vanillaFogCol,
                   const vec3 relPos, const vec3 shadowLightPos, const vec3 normal,
                   const float torchLevel, const float indoor, const float shadowLightLevel, const float daylight, const float rainLevel,
                   const float shaderAO, const float vanillaAO, const float R, const float F0,
                   out vec3 bloom) {
    vec3 result = vec3(0.0);
	
	vec3 totalLight = vec3(0.0);
	vec3 dirLight   = vec3(0.0);
	vec3 undirLight = vec3(0.0);

    float totalAO = clamp(vanillaAO * 1.5 + shaderAO * 1.0, 0.0, 1.0);

    undirLight += getAmbientLight(normalize(relPos), shadowLightPos, skyCol, vanillaSkyCol, vanillaFogCol, torchLevel, indoor, shadowLightLevel, daylight, 1.0) * (1.0 - totalAO);
	undirLight += getTorchLight(torchLevel, indoor, shadowLightLevel, daylight) * (1.0 - totalAO);
	dirLight   += getSunlight(indoor, shadowLightLevel, daylight, rainLevel) * (1.0 - totalAO);
	dirLight   += getMoonlight(indoor, shadowLightLevel, daylight, rainLevel) * (1.0 - totalAO);
	undirLight += getSkyLight(normalize(relPos), shadowLightPos, skyCol, vanillaSkyCol, vanillaFogCol, rainLevel, indoor, shadowLightLevel, daylight) * (1.0 - totalAO);

	totalLight = dirLight + undirLight;

    // Apply coloured shadows
	totalLight += totalLight * ((normalize(totalLight) + 1.0) * 0.5 - (1.0 - shadows.rgb)) * (1.0 - totalAO);
	
    result = albedo.rgb * totalLight;

    vec3 incomingLight = (dirLight + undirLight) * 0.03;
    vec3 dirLightRatio = dirLight / max(vec3(0.01), incomingLight);

	vec3 specular = getPBRSpecular(normal, normalize(-relPos), shadowLightPos, R, F0);
	vec3 fresnel  = fresnelSchlick(normalize(-relPos), shadowLightPos, vec3(F0));

	vec3 reflectedLight = (specular * dirLightRatio) * 6.0 * mix(0.005, 1.0, smoothstep(0.0, 0.1, daylight)); // Reflected directional light
	reflectedLight 	   += (fresnel * incomingLight)  * 0.3; // Reflected undirectional light
	result += reflectedLight;
 
#   if defined GBUFFERS_TRANSLUCENT
        bloom = (specular * dirLightRatio) * mix(0.03, 1.0, smoothstep(0.0, 0.1, daylight)) * (1.0 - rainLevel);
#   else
        bloom = (specular * dirLightRatio) * 0.03 * mix(0.03, 1.0, smoothstep(0.0, 0.1, daylight)) * (1.0 - rainLevel);
#   endif

    return result;
}

#endif /* !defined MUSK_ROSE_LIGHT_GLSL_INCLUDED */