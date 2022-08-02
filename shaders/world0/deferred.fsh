#version 120
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform vec3 cameraPosition;

varying vec2 uv;
varying vec3 sunPos, moonPos, shadowLitPos;

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
	
	float distortFact = getDistortFact(shadowPos.xy);
	shadowPos.xyz = distort(shadowPos.xyz);
	shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
	
	shadowPos.z -= SHADOW_BIAS * (distortFact * distortFact) / abs(diffuse);

	return shadowPos;
}

const float sunPathRotation = -40.0; // [-50  -45 -40  -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45 50]
const int shadowMapResolution = 1024; // [512 1024 2048 4096]
const float shadowDistance = 512.0;

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
float depth = texture2D(depthtex0, uv).r;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos  = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
float diffuse = max(0.0, dot(shadowLitPos, normal));
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));

if (depth == 1.0) {
} else {
vec4 shadows = vec4(vec3(diffuse), 1.0);
vec4 shadowPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPos, uv, depth, diffuse);
if (diffuse > 0.0) {
    if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
        if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
            shadows = vec4(vec3(0.0), 0.0);
        } else {
            shadows = vec4(texture2D(shadowcolor0, shadowPos.xy).rgb, 0.0);
        }
    }
}

albedo += vec3(1.4) - (1.0 - shadows.rgb);
albedo *= 0.5;
albedo = pow(albedo, vec3(2.0));
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