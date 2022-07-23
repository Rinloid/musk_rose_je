#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D shadowtex0;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform float far, near;
uniform float viewWidth, viewHeight;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform int isEyeInWater;

varying vec2 uv;
varying vec3 shadowLitPos, sunPos, moonPos;

#include "utilities/muskRoseWater.glsl"
#include "utilities/muskRoseSky.glsl"
#include "utilities/muskRoseClouds.glsl"
#include "utilities/muskRoseSpecular.glsl"

/*
 ** Generate a TBN matrix without tangent and binormal.
*/
mat3 getTBNMatrix(const vec3 normal) {
    vec3 T = vec3(abs(normal.y) + normal.z, 0.0, normal.x);
    vec3 B = cross(T, normal);
    vec3 N = vec3(-normal.x, normal.y, normal.z);
 
    return mat3(T, B, N);
}

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

vec3 viewPos2UV(const vec3 viewPos, const mat4 proj) {
    vec4 clipSpace = proj * vec4(viewPos, 1.0);
	
    return ((clipSpace.xyz / clipSpace.w) * 0.5 + 0.5).xyz;
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec3 getRayTraceFactor(const vec3 viewPos, const vec3 reflectPos) {
	const int refinementSteps = 6;
	const int raySteps = 28;

	vec3 rayPosHit = vec3(0.0);
	
	vec3 refPos = reflectPos;
	vec3 startPos = viewPos + refPos;
	vec3 tracePos = refPos;

    int sr = 0;
    for (int i = 0; i < raySteps; i++) {
        vec3 uv = nvec3(gbufferProjection * vec4(startPos, 1.0)) * 0.5 + 0.5;
       
	    if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1 || uv.z < 0 || uv.z > 1.0) {
			break;
		}

        vec3 viewPos1 = getViewPos(gbufferProjectionInverse, uv.xy, texture2D(depthtex0, uv.xy).x).xyz;
		if (distance(startPos, viewPos1) < length(refPos) * length(refPos)) {
			sr++;
			if (sr >= refinementSteps) {
				rayPosHit = vec3(uv.xy, 1.0);
				break;
			}

			tracePos -= refPos;
			refPos *= 0.07;
        }

        refPos *= 2.2;
        tracePos += refPos;
		startPos = viewPos + tracePos;
	}

    return rayPosHit;
}

#define RAY_COL vec3(1.0, 0.85, 0.63)

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
vec4 bloom = texture2D(gaux2, uv);
float depth = texture2D(depthtex0, uv).r;
vec3 worldNormal = texture2D(gnormal, uv).rgb;
float reflectance = texture2D(gnormal, uv).a;
vec2 uv0 = texture2D(gaux1, uv).rg;
vec2 uv1 = texture2D(gaux1, uv).ba;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));
float cosTheta = abs(dot(normalize(relPos), worldNormal));
float diffuse = max(0.0, dot(shadowLitPos, worldNormal));

vec3 fogCol = getAtmosphere(normalize(relPos), shadowLitPos, vec3(0.4, 0.65, 1.0), skyBrightness);
fogCol = toneMapReinhard(fogCol);
fogCol = mix(fogColor, fogCol, uv1.y);
	
float fogFact = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);
float rayFact = clamp((length(relPos * (duskDawn * 4.0)) - near) / (far - near), 0.0, 1.0);

float outdoor = smoothstep(0.92, 0.95, uv1.y);

float rays = 0.0;
vec3 relPosRay = relPos;
relPosRay.xyz *= mix(1.0, 1.3, hash12(floor(gl_FragCoord.xy * 2048.0) + frameTimeCounter));
while (dot(relPosRay.xyz, relPosRay.xyz) > 0.25 * 0.25) {
	relPosRay.xyz *= 0.75;
	vec4 rayPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPosRay, uv, depth, 1.0);
	if (texture2D(shadowtex0, rayPos.xy).r > rayPos.z) {
		rays = mix(rayPos.w, rays, exp2(length(relPosRay.xyz) * -0.0625));
	}
}

if (reflectance > 0.5 && depth < 1.0) {
	worldNormal = normalize(getWaterWavNormal(fragPos.xz, frameTimeCounter) * getTBNMatrix(worldNormal));
	vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * worldNormal);
	vec3 refUV = viewPos2UV(refPos, gbufferProjection);
	vec3 rayPosHit = getRayTraceFactor(viewPos, refPos);

	vec3 refracted = texture2D(gaux3, refract(vec3(uv, 1.0), getWaterWavNormal(fragPos.xz, frameTimeCounter) * 0.12, 1.0).xy).rgb;

	float screenSpace = float(rayPosHit.x > 0.0 && rayPosHit.x < 1.0 && rayPosHit.y > 0.0 && rayPosHit.y < 1.0 && refUV.z > 0.0 && refUV.z < 1.0) * (1.0 - max(abs(rayPosHit.x - 0.5), abs(rayPosHit.y - 0.5)) * 2.0);

	vec3 ssr = albedo;
	if (rayPosHit.b > 0.5) {
		ssr = texture2D(gcolor, rayPosHit.xy + hash22(floor(uv * 2048.0)) * 0.002).rgb;
	}
	vec3 reflected = mix(albedo, ssr, step(0.01, screenSpace));

	albedo = mix(reflected, refracted, cosTheta);

	albedo += min(specularLight(10.0, 200.0, sunPos, relPos, worldNormal), 1.0) * outdoor;

	albedo = mix(albedo, RAY_COL, rayFact * 0.5);
	albedo = mix(albedo, fogCol, fogFact);
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