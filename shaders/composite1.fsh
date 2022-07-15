#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float far, near;
uniform vec3 cameraPosition;
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

vec3 uv2ViewPos(const vec2 uv, const mat4 projInv, const float depth) {
    vec3 pos = vec3(uv, depth);
	vec4 iProjDiag = vec4(projInv[0].x, projInv[1].y, projInv[2].zw);
	vec3 p3 = pos * 2.0 - 1.0;
    vec4 view = iProjDiag * p3.xyzz + projInv[3];

    return view.xyz / view.w;
}

vec3 viewPos2UV(const vec3 viewPos, const mat4 proj) {
    vec4 clipSpace = proj * vec4(viewPos, 1.0);
	
    return ((clipSpace.xyz / clipSpace.w) * 0.5 + 0.5).xyz;
}

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
float depth = texture2D(depthtex0, uv).r;
vec3 worldNormal = texture2D(gnormal, uv).rgb;
float reflectance = texture2D(gnormal, uv).a;
float outdoor = texture2D(gaux1, uv).a;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
float daylight = sin(sunPos.y);
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.5, 2.0, smoothstep(0.0, 0.1, daylight));
float cosTheta = abs(dot(normalize(relPos), worldNormal));

if (reflectance > 0.5 && depth < 1.0) {
	worldNormal = getWaterWavNormal(fragPos.xz, frameTimeCounter) * getTBNMatrix(worldNormal);
	vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * worldNormal);
	vec3 refUV = viewPos2UV(refPos, gbufferProjection);

	vec2 underWaterBlur = hash22(floor(uv * 2048.0)) * 0.0016;
	vec3 refracted = texture2D(gcolor, refract(vec3(uv, 1.0), getWaterWavNormal(fragPos.xz, frameTimeCounter) * 0.15, 1.0).xy).rgb;

	vec3 reflectedSSR = texture2D(gcolor, refUV.xy).rgb;
	float screenSpace = float(refUV.x > 0.0 && refUV.x < 1.0 && refUV.y > 0.0 && refUV.y < 1.0 && refUV.z > 0.0 && refUV.z < 1.0) * (1.0 - max(abs(refUV.x - 0.5), abs(refUV.y - 0.5)) * 2.0);

	vec3 reflectedSky = getAtmosphere(reflect(normalize(relPos), worldNormal), sunPos, vec3(0.4, 0.65, 1.0), skyBrightness);
	reflectedSky = toneMapReinhard(reflectedSky);

	vec4 clouds = renderClouds(reflect(normalize(relPos), worldNormal), cameraPosition, sunPos, smoothstep(0.0, 0.25, daylight), rainStrength, frameTimeCounter);

    reflectedSky = mix(reflectedSky, clouds.rgb, clouds.a * 0.65);

	vec3 reflected = mix(reflectedSky, reflectedSSR, smoothstep(0.0, 0.1, screenSpace));
	if (isEyeInWater == 1) {
		reflected = albedo;
	}

	albedo = mix(reflected, refracted, cosTheta);

	albedo += min(specularLight(6.5, 50.0, sunPos, relPos, worldNormal), 1.0);
}

if (depth < 1.0) {
    vec3 fogCol = getAtmosphere(normalize(relPos), sunPos, vec3(0.4, 0.65, 1.0), skyBrightness);
    fogCol = toneMapReinhard(fogCol);
	float fogFact = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);
	
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