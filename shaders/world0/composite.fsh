#version 120
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform float far, near;

varying vec2 uv;
varying vec3 sunPos, moonPos, shadowLightPos;

vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
	vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

	return viewPos / viewPos.w;
}

vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
	vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
	
	return relPos / relPos.w;
}

#include "/utilities/muskRoseShadow.glsl"

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

#include "/utilities/muskRoseSky.glsl"

#define SKY_COL  vec3(0.4, 0.65, 1.0)

#define AMBIENT_LIGHT_INTENSITY 10.0
#define SKYLIGHT_INTENSITY 20.0
#define SUNLIGHT_INTENSITY 30.0
#define MOONLIGHT_INTENSITY 10.0
#define TORCHLIGHT_INTENSITY 60.0

#define SKYLIGHT_COL vec3(0.9, 0.98, 1.0)
#define SUNLIGHT_COL vec3(1.0, 0.9, 0.85)
#define SUNLIGHT_COL_SET vec3(1.0, 0.60, 0.1)
#define TORCHLIGHT_COL vec3(1.0, 0.65, 0.3)
#define MOONLIGHT_COL vec3(0.5, 0.65, 1.0)

#define EXPOSURE_BIAS 5.2
#define GAMMA 2.2

const float sunPathRotation = -40.0; // [-50  -45 -40  -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50]
const int shadowMapResolution = 1024; // [512 1024 2048 4096]
const float shadowDistance = 512.0;

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
vec2 uv1 = texture2D(gaux1, uv).rg;
float depth = texture2D(depthtex0, uv).r;
float blendFlag = texture2D(gaux1, uv).b;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos  = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
vec3 skyPos = normalize(relPos);
float diffuse = max(0.0, dot(shadowLightPos, normal));
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));
float amnientLightFactor = 1.0;
float dirLightFactor = 0.0;
float emissiveLightFactor = 0.0;
float clearWeather = 1.0 - rainStrength;
vec3 sky = getSky(skyPos, shadowLightPos, SKY_COL, skyBrightness);
vec3 sunlightCol = mix(SUNLIGHT_COL, SUNLIGHT_COL_SET, duskDawn);
vec3 daylightCol = mix(sky, sunlightCol, 0.4);
vec3 ambientLightCol = vec3(1.0);
vec4 shadows = vec4(vec3(diffuse), 1.0);

vec3 light = vec3(0.0);

if (blendFlag > 0.5) {
    #include "lighting.glsl"
}

    /* DRAWBUFFERS:0
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
}