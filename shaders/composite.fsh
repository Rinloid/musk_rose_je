#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D shadowtex0;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowProjection, shadowModelView;
uniform float far, near;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform int isEyeInWater;

varying vec2 uv;
varying vec3 shadowLitPos, sunPos, moonPos;

#include "utilities/muskRoseWater.glsl"
#include "utilities/muskRoseSky.glsl"
#include "utilities/muskRoseClouds.glsl"
#include "utilities/muskRoseSpecular.glsl"

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

/*
 ** Uncharted 2 tone mapping
 ** Link (deleted): http://filmicworlds.com/blog/filmic-tonemapping-operators/
 ** Archive: https://bit.ly/3NSGy4r
 */
vec3 uncharted2ToneMap_(vec3 x) {
    const float A = 0.017; // Shoulder strength
    const float B = 0.50;  // Linear strength
    const float C = 0.02;  // Linear angle
    const float D = 0.08; // Toe strength
    const float E = 0.01;  // Toe numerator
    const float F = 0.50;  // Toe denominator

    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}
vec3 uncharted2ToneMap(vec3 frag, float exposureBias) {
    const float whiteLevel = 112.0;

    vec3 curr = uncharted2ToneMap_(exposureBias * frag);
    vec3 whiteScale = 1.0 / uncharted2ToneMap_(vec3(whiteLevel, whiteLevel, whiteLevel));
    vec3 color = curr * whiteScale;

    return clamp(color, 0.0, 1.0);
}

vec3 contrastFilter(vec3 color, float contrast) {
    float t = 0.5 - contrast * 0.5;

    return clamp(color * contrast + t, 0.0, 1.0);
}

const float ambientOcclusionLevel = 1.0;
const float sunPathRotation = -40.0;
const float shadowMapResolution = 1024.0;
const float shadowDistance = 512.0; 

#define AMBIENT_LIGHT_INTENSITY 20.0
#define SKYLIGHT_INTENSITY 2.0
#define SUNLIGHT_INTENSITY 70.0
#define RAY_INTENSITY 2.0
#define MOONLIGHT_INTENSITY 1.2
#define TORCHLIGHT_INTENSITY 2.0

#define SKYLIT_COL vec3(0.9, 0.98, 1.0)
#define SUNLIT_COL vec3(1.0, 0.9, 0.75)
#define SUNLIT_COL_SET vec3(1.0, 0.60, 0.2)
#define RAY_COL vec3(1.0, 0.85, 0.63)
#define TORCHLIT_COL vec3(1.0, 0.65, 0.3)
#define MOONLIT_COL vec3(0.75, 0.8, 1.0)

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
float depth = texture2D(depthtex0, uv).r;
vec3 worldNormal = texture2D(gnormal, uv).rgb;
float reflectance = texture2D(gnormal, uv).a;
vec2 uv0 = texture2D(gaux1, uv).rg;
vec2 uv1 = texture2D(gaux1, uv).ba;
vec4 bloom = texture2D(gaux2, uv);
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
float cosTheta = abs(dot(normalize(relPos), worldNormal));
float daylight = sin(sunPos.y);
float outdoor = 1.0;
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.5, 2.0, smoothstep(0.0, 0.1, daylight));

if (depth == 1.0) {
    vec3 skyPos = normalize(relPos);
    vec2 cloudPos = skyPos.xz / skyPos.y;

	albedo = getAtmosphere(skyPos, sunPos, vec3(0.4, 0.65, 1.0), skyBrightness);
	albedo = toneMapReinhard(albedo);

    vec4 clouds = renderClouds(skyPos, cameraPosition, sunPos, smoothstep(0.0, 0.25, daylight), rainStrength, frameTimeCounter);

    albedo = mix(albedo, clouds.rgb, clouds.a * 0.65);
    bloom += drawSun(cross(skyPos, sunPos) * 500.0);
} else if (reflectance < 0.5) {
	float diffuse = max(0.0, dot(shadowLitPos, worldNormal));

    float shadows = 0.0;
    if (diffuse > 0.0 && bool(step(0.5, uv1.y))) {
        vec4 shadowPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPos, uv, depth, diffuse);
        if (shadowPos.w > 0.0) {
            for (int i = 0; i < shadowSamples.length(); i++) {
                vec2 offset = vec2(shadowSamples[i] / float(shadowMapResolution));
                if (texture2D(shadowtex0, shadowPos.xy + offset).r > shadowPos.z) {
                    shadows += shadowPos.w;
                }
            } shadows /= float(shadowSamples.length());
        }
    }

    outdoor = shadows;

    float rays = 0.0;
    vec3 relPosRay = relPos;
    relPosRay.xyz *= mix(1.0, 1.3, hash12(floor(gl_FragCoord.xy * 1024.0) + frameTimeCounter));
    while (dot(relPosRay.xyz, relPosRay.xyz) > 0.25 * 0.25) {
        relPosRay.xyz *= 0.75;
        vec4 rayPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPosRay, uv, depth, 1.0);
        if (texture2D(shadowtex0, rayPos.xy).r > rayPos.z) {
            rays = mix(rayPos.w, rays, exp2(length(relPosRay.xyz) * -0.0625));
        }
    }

    float specularLight = specularLight(1.8, 0.2, sunPos, relPos, worldNormal);
	float dirLight = mix(0.0, mix(0.0, specularLight, shadows), outdoor);
	float torchLit = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
	// torchLit = mix(0.0, torchLit, smoothstep(0.95, 0.5, uv1.y * daylight));

	vec3 defaultCol = vec3(1.0, 1.0, 1.0);
	vec3 ambientLightCol = mix(mix(1.0 / vec3(AMBIENT_LIGHT_INTENSITY) + 0.3, TORCHLIT_COL, torchLit), mix(MOONLIT_COL, mix(SKYLIT_COL, SUNLIT_COL, 0.625), daylight), uv1.y);
    // ambientLightCol = mix(vec3(0.3, 0.3, 0.3), ambientLightCol, getAO(col, 0.65));
    float ao = getSSAO(viewPos, gbufferProjectionInverse, uv, aspectRatio, depthtex0);

	vec3 lit = vec3(1.0, 1.0, 1.0);

	lit *= mix(defaultCol, AMBIENT_LIGHT_INTENSITY * ambientLightCol, 1.0 - ao * 0.65);
	lit *= mix(defaultCol, SKYLIGHT_INTENSITY * SKYLIT_COL, dirLight * daylight * max(0.5, 1.0 - rainStrength));
	lit *= mix(defaultCol, SUNLIGHT_INTENSITY * mix(SUNLIT_COL, SUNLIT_COL_SET, duskDawn), dirLight * daylight * max(0.5, 1.0 - rainStrength));
    //lit = mix(lit, RAY_INTENSITY * RAY_COL, rays * duskDawn * max(0.5, 1.0 - rainStrength));
    lit *= mix(defaultCol, MOONLIGHT_INTENSITY * MOONLIT_COL, (1.0 - dirLight) * (1.0 - daylight) * max(0.5, 1.0 - rainStrength));
    lit *= mix(defaultCol, TORCHLIGHT_INTENSITY * TORCHLIT_COL, torchLit);

	albedo *= lit;
	albedo = uncharted2ToneMap(albedo, 1.0);
	albedo = contrastFilter(albedo, 1.2);

    float rayFact = clamp((length(relPos * (duskDawn)) - near) / (far - near), 0.0, 1.0);
    albedo = mix(albedo, RAY_COL, rays * rayFact);

    vec3 fogCol = getAtmosphere(normalize(relPos), sunPos, vec3(0.4, 0.65, 1.0), skyBrightness);
    fogCol = toneMapReinhard(fogCol);
        
    float fogFact = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);

    albedo = mix(albedo, fogCol, fogFact);
}

	/* DRAWBUFFERS:045
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
    gl_FragData[1] = vec4(vec3(0.0), outdoor); // gaux1
    gl_FragData[2] = bloom; // gaux2
}