#if !defined LIGHTING_INCLUDED
#define LIGHTING_INCLUDED 1

#if defined FORWARD_FRAGMENT
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float far, near;
uniform float aspectRatio;
uniform int moonPhase;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 fogColor;

varying vec2 uv;
varying vec3 sunPos, moonPos, shadowLightPos;

#include "/utilities/muskRoseWater.glsl"

vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
	vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

	return viewPos / viewPos.w;
}

vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
	vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
	
	return relPos / relPos.w;
}

#include "/utilities/muskRoseShadow.glsl"

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

#include "/utilities/muskRoseSSAO.glsl"

#define AMBIENT_LIGHT_INTENSITY 10.0
#define TORCHLIGHT_INTENSITY 120.0

#define TORCHLIGHT_COL vec3(0.3, 1.0, 0.65)

#define EXPOSURE_BIAS 5.2
#define GAMMA 2.2

const float sunPathRotation = -40.0; // [-50  -45 -40  -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50]
const int shadowMapResolution = 2048; // [512 1024 2048 4096]
const float shadowDistance = 512.0;
const float occlShadowDepth = 0.6;

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
#if defined FORWARD_DEFERRED
    vec3 backward = albedo;
#endif
vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
vec2 uv1 = texture2D(gaux1, uv).rg;
float blendFlag = texture2D(gaux1, uv).b;
float waterFlag = texture2D(gaux3, uv).r;
float blendAlpha = texture2D(gaux3, uv).g;
float rackFlag = texture2D(gaux3, uv).b;
float depth = texture2D(depthtex0, uv).r;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos  = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
vec3 skyPos = normalize(relPos);
float diffuse = max(0.0, dot(shadowLightPos, normal));
float ambientLightFactor = 1.0;
float emissiveLightFactor = 0.0;
vec3 ambientLightCol = vec3(1.0);
float ao = getSSAO(viewPos, gbufferProjectionInverse, uv, aspectRatio, depthtex0);
float occlShadow = mix(1.0, occlShadowDepth, ao);

vec3 light = vec3(0.0);

#if defined FORWARD_DEFERRED
    if (depth == 1.0) {
        albedo = vec3(0.65, 0.0, 1.0);
    } else
#elif defined FORWARD_COMPOSITE
    if (blendFlag > 0.5 || rackFlag > 0.5)
#endif
{
    emissiveLightFactor = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
    ambientLightCol = vec3(0.65, 0.0, 1.0);
    ambientLightCol += 1.0 - max(max(ambientLightCol.r, ambientLightCol.g), ambientLightCol.b);
    light += ambientLightCol * AMBIENT_LIGHT_INTENSITY * occlShadow;
    light += TORCHLIGHT_COL * TORCHLIGHT_INTENSITY * emissiveLightFactor * blendAlpha;

    albedo *= light;
    albedo = hdrExposure(albedo, EXPOSURE_BIAS, 0.2 + 0.02 * (1.0 - blendAlpha));
    albedo = uncharted2ToneMap(albedo, EXPOSURE_BIAS);
    albedo = contrastFilter(albedo, 1.2);

    float fogFactor = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);
    albedo = mix(albedo, vec3(0.65, 0.0, 1.0), fogFactor);
}

#if defined FORWARD_DEFERRED
    backward = albedo;
#endif

    /* DRAWBUFFERS:05
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
#   if defined FORWARD_DEFERRED
    gl_FragData[1] = vec4(backward, 1.0); // gaux2
#   endif
}
#endif /* defined FORWARD_FRAGMENT */

#if defined FORWARD_VERTEX
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform vec3 sunPosition, moonPosition, shadowLightPosition;

varying vec2 uv;
varying vec3 sunPos, moonPos, shadowLightPos;

void main() {
uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
sunPos         = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * sunPosition);
moonPos        = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * moonPosition);
shadowLightPos = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * shadowLightPosition);

	gl_Position = ftransform();
}
#endif /* defined FORWARD_VERTEX */

#endif /* !defined LIGHTING_INCLUDED */