#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform float far, near;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform int isEyeInWater;
uniform int moonPhase;

varying vec2 uv;
varying vec3 shadowLitPos, sunPos, moonPos;

#include "utilities/settings.glsl"
#include "utilities/muskRoseWater.glsl"
#include "utilities/muskRoseSky.glsl"
#include "utilities/muskRoseClouds.glsl"
#include "utilities/muskRoseSpecular.glsl"
#include "utilities/noiseFunctions.glsl"

vec3 uv2ViewPos(const vec2 uv, const mat4 projInv, const float depth) {
    vec3 pos = vec3(uv, depth);
	vec4 iProjDiag = vec4(projInv[0].x, projInv[1].y, projInv[2].zw);
	vec3 p3 = pos * 2.0 - 1.0;
    vec4 view = iProjDiag * p3.xyzz + projInv[3];

    return view.xyz / view.w;
}

#include "utilities/muskRoseSSAO.glsl"

vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
	vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

	return viewPos / viewPos.w;
}

vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
	vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
	
	return relPos / relPos.w;
}

#include "utilities/muskRoseShadow.glsl"

#define SHADOW_BIAS 0.03 // [0.00 0.01 0.02 0.03 0.04 0.05]

vec4 getShadowPos(const mat4 modelViewInv, const mat4 projInv, const mat4 shadowModelView, const mat4 shadowProj, const vec3 relPos, const vec2 uv, const float depth, const float diffuse) {
	vec4 shadowPos = vec4(relPos, 1.0);
	shadowPos = shadowProj * (shadowModelView * shadowPos);
	
	float distortFactor = getDistortFactor(shadowPos.xy);
	shadowPos.xyz = distort(shadowPos.xyz);
	shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
	
	shadowPos.z -= SHADOW_BIAS * (distortFactor * distortFactor) / abs(diffuse);

	return shadowPos;
}

float getLuma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float getAO(vec4 vertexCol, const float shrinkLevel) {
    float lum = vertexCol.g * 2.0 - (vertexCol.r < vertexCol.b ? vertexCol.r : vertexCol.b);

    return min(lum + (1.0 - shrinkLevel), 1.0);
}

vec3 hdrExposure(const vec3 col, const float overExposure, const float underExposure) {
    vec3 overExposed   = col / overExposure;
    vec3 normalExposed = col;
    vec3 underExposed  = col * underExposure;

    return mix(overExposed, underExposed, normalExposed);
}

/*
 ** Uncharted 2 tone mapping
 ** Link (deleted): http://filmicworlds.com/blog/filmic-tonemapping-operators/
 ** Archive: https://bit.ly/3NSGy4r
 */
vec3 uncharted2ToneMap_(vec3 x) {
    const float A = 0.015; // Shoulder strength
    const float B = 0.500; // Linear strength
    const float C = 0.100; // Linear angle
    const float D = 0.010; // Toe strength
    const float E = 0.020; // Toe numerator
    const float F = 0.300; // Toe denominator

    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}
vec3 uncharted2ToneMap(const vec3 col, const float exposureBias) {
    const float whiteLevel = 256.0;

    vec3 curr = uncharted2ToneMap_(exposureBias * col);
    vec3 whiteScale = 1.0 / uncharted2ToneMap_(vec3(whiteLevel, whiteLevel, whiteLevel));
    vec3 color = curr * whiteScale;

    return clamp(color, 0.0, 1.0);
}

vec3 contrastFilter(const vec3 col, const float contrast) {
    return (col - 0.5) * max(contrast, 0.0) + 0.5;
}

const float ambientOcclusionLevel = 1.0;
const float sunPathRotation = -40.0; // [-50  -45 -40  -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50]
const int shadowMapResolution = 1024; // [512 1024 2048 4096]
const float shadowDistance = 512.0; 

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
vec3 albedoUnderwater = albedo;
float depth = texture2D(depthtex0, uv).r;
float reflectance = texture2D(gaux1, uv).r;
vec2 uv1 = texture2D(gaux1, uv).ba;
vec4 bloom = texture2D(gaux2, uv);
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
vec3 worldNormal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
float cosTheta = abs(dot(normalize(relPos), worldNormal));
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));

float diffuse = max(0.0, dot(shadowLitPos, worldNormal));

float shadows = 0.0;
#ifndef ENABLE_BEDROCK_SHADOWS
    if (diffuse > 0.0 && bool(step(0.5, uv1.y))) {
        vec4 shadowPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPos, uv, depth, diffuse);
        if (shadowPos.w > 0.0) {
            for (int i = 0; i < shadowSamples.length(); i++) {
                vec2 offset = vec2(shadowSamples[i] / float(shadowMapResolution));
                if (texture2D(shadowtex0, shadowPos.xy + offset * 0.5 + hash12(floor(uv * 2048.0) + float(i / shadowSamples.length())) * 0.00025).r > shadowPos.z) {
                    shadows += shadowPos.w;
                }
            } shadows /= float(shadowSamples.length());
        }
    }
#else
    shadows = smoothstep(0.95, 0.96, uv1.y);
#endif

float rays = 0.0;
vec3 relPosRay = relPos;
relPosRay.xyz *= mix(1.0, 1.3, hash12(floor(uv * 2048.0) + frameTimeCounter));
while (dot(relPosRay.xyz, relPosRay.xyz) > 0.25 * 0.25) {
    relPosRay.xyz *= 0.75;
    vec4 rayPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPosRay, uv, depth, 1.0);
    if (texture2D(shadowtex0, rayPos.xy).r > rayPos.z) {
        rays = mix(rayPos.w, rays, exp2(length(relPosRay.xyz) * -0.0625));
    }
}

if (depth == 1.0) {
    vec3 skyPos = normalize(relPos);
    vec2 cloudPos = skyPos.xz / skyPos.y;

	albedo = getAtmosphere(skyPos, shadowLitPos, SKY_COL, skyBrightness);
	albedo = toneMapReinhard(albedo);

    vec4 clouds = renderClouds(skyPos, cameraPosition, shadowLitPos, smoothstep(0.0, 0.25, daylight), rainStrength, frameTimeCounter);
    float moon = mix(drawMoon(cross(skyPos, moonPos) * 127.0, getMoonPhase(moonPhase), 10.0), 0.0, smoothstep(0.0, 0.1, daylight));

    albedo = mix(albedo, clouds.rgb, clouds.a * 0.65);
    albedo = mix(albedo, MOON_COL * mix(1.0, 0.85, clamp(simplexNoise(cross(skyPos, moonPos).xz / 0.06), 0.0, 1.0)), moon);
} else if (reflectance < 0.5) {
    float specular = specularLight(1.8, 0.02, shadowLitPos, relPos, worldNormal);
    #ifndef ENABLE_SPECULAR
        specular = diffuse * 0.1;
    #endif
	float dirLight = mix(0.0, specular, shadows);
	float torchLit = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
	torchLit = mix(0.0, torchLit, smoothstep(0.96, 0.6, uv1.y * smoothstep(0.0, 0.5, daylight)));

	vec3 defaultCol = vec3(1.0, 1.0, 1.0);
	vec3 ambientLightCol = mix(mix(1.0 / vec3(AMBIENT_LIGHT_INTENSITY), TORCHLIT_COL, torchLit), mix(MOONLIT_COL, mix(SKYLIT_COL, SUNLIT_COL, 0.625), daylight), uv1.y);
    float ao =
    #ifdef ENABLE_SSAO
        getSSAO(viewPos, gbufferProjectionInverse, uv, aspectRatio, depthtex0);
    #else
        0.0;
    #endif

	vec3 lit = vec3(1.0, 1.0, 1.0);

	lit *= mix(defaultCol, AMBIENT_LIGHT_INTENSITY * max(0.2, daylight) * ambientLightCol, (1.0 - ao * 0.65));
	lit *= mix(defaultCol, SKYLIGHT_INTENSITY * SKYLIT_COL, dirLight * daylight * max(0.5, 1.0 - rainStrength));
	lit *= mix(defaultCol, SUNLIGHT_INTENSITY * mix(SUNLIT_COL, SUNLIT_COL_SET, duskDawn), dirLight * daylight * max(0.5, 1.0 - rainStrength));
    lit *= mix(defaultCol, MOONLIGHT_INTENSITY * MOONLIT_COL, dirLight * (1.0 - daylight) * max(0.5, 1.0 - rainStrength));
    lit *= mix(defaultCol, TORCHLIGHT_INTENSITY * TORCHLIT_COL, torchLit);

	albedo *= albedo * lit;

    albedo = pow(albedo, vec3(1.0 / GAMMA));
    albedo = hdrExposure(albedo, 5.0, 0.5);
	albedo = uncharted2ToneMap(albedo, 5.0);

    #ifdef ENABLE_LIGHT_RAYS
        float rayFact = clamp((length(relPos * (duskDawn * 4.0)) - near) / (far - near), 0.0, 1.0);
        albedo = mix(albedo, RAY_COL, rays * rayFact * 0.5);
    #endif

    vec3 fogCol = getAtmosphere(normalize(relPos), shadowLitPos, SKY_COL, max(0.7, skyBrightness * smoothstep(0.0, 0.5, uv1.y)));
    fogCol = toneMapReinhard(fogCol);
        
    float fogFact = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);

    albedoUnderwater = albedo;
    #ifdef ENABLE_UNDERWATER_CAUSTICS
        if (isEyeInWater == 0) {
            albedoUnderwater *= mix(defaultCol, lit, getWaterWav(fragPos.xz, frameTimeCounter) * 0.02);
        } else if (isEyeInWater == 1) {
            albedo *= mix(defaultCol, lit, getWaterWav(fragPos.xz, frameTimeCounter) * 0.02);
        }
    #endif

    #ifdef ENABLE_UNDERWATER_FOG
        if (isEyeInWater == 0) {
            albedoUnderwater *= mix(vec3(1.0), vec3(0.0, 0.5, 0.9), clamp(fogFact * 10.0, 0.0, 1.0) * 0.55);
        } else if (isEyeInWater == 1) {
            albedo *= mix(vec3(1.0), vec3(0.0, 0.5, 0.9), clamp(fogFact * 10.0, 0.0, 1.0) * 0.55);
        }
    #endif

    #ifdef ENABLE_FOG
        albedo = mix(albedo, fogCol, fogFact);
    #endif
}

	/* DRAWBUFFERS:06
     * 0 = gcolor
     * 1 = gdepth
     * 2 = gnormal
     * 3 = composite
     * 4 = gaux1
     * 5 = gaux2
     * 6 = gaux3
     * 7 = gaux4
	*/
	gl_FragData[0] = vec4(albedo, 1.0); // gcolor
    gl_FragData[1] = vec4(albedoUnderwater, 1.0); // gaux3
}