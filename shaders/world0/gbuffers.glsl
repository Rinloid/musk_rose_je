#if defined FRAGMENT
uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D gaux1;
uniform float viewWidth, viewHeight;
uniform float rainStrength;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec4 entityColor;
uniform int isEyeInWater;
uniform int moonPhase;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 shadowLitPos, sunPos, moonPos;
varying vec3 normal;
varying vec3 viewPos;
varying vec3 relPos;
varying vec3 fragPos;
flat varying float waterFlag;
flat varying float bloomFlag;
flat varying float blendFlag;
flat varying float tintFlag;

#include "utilities/settings.glsl"
#include "utilities/muskRoseWater.glsl"
#include "utilities/muskRoseSky.glsl"
#include "utilities/muskRoseClouds.glsl"

/*
 ** Generate a TBN matrix without tangent and binormal.
*/
mat3 getTBNMatrix(const vec3 normal) {
    vec3 T = vec3(abs(normal.y) + normal.z, 0.0, normal.x);
    vec3 B = cross(T, normal);
    vec3 N = vec3(-normal.x, normal.y, normal.z);
 
    return mat3(T, B, N);
}

vec3 viewPos2UV(const vec3 viewPos, const mat4 proj) {
    vec4 clipSpace = proj * vec4(viewPos, 1.0);
	
    return ((clipSpace.xyz / clipSpace.w) * 0.5 + 0.5).xyz;
}

void main() {
vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
vec4 albedo = texture2D(texture, uv0);
albedo.rgb *= col.rgb;
#ifdef ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif

float outdoor = smoothstep(0.5, 0.6, uv1.y);
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));

if (waterFlag > 0.5 || blendFlag > 0.5 || tintFlag > 0.5) {
    vec3 worldNormal = normal;
    if (waterFlag > 0.5) {
        worldNormal = normalize(getWaterWavNormal(fragPos.xz, frameTimeCounter) * getTBNMatrix(normal));
    }
    float cosTheta = abs(dot(normalize(relPos), normal));

    if (waterFlag > 0.5) {
        albedo.rgb = vec3(0.0, 0.15, 0.3);
        albedo.a = 1.0;
        if (isEyeInWater == 1) {
            albedo.a = 0.5;
        }
    }

    vec3 skyPos = reflect(normalize(relPos), worldNormal);
    vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * worldNormal);
	vec3 refUV = viewPos2UV(refPos, gbufferProjection);
	vec3 reflectedSky = vec3(0.0);
	vec4 clouds = vec4(0.0);
    float moon = 0.0;

    #ifdef ENABLE_SKY_REFLECTION
        if (!bool(1.0 - outdoor) && isEyeInWater == 0) {
            reflectedSky = getAtmosphere(skyPos, shadowLitPos, SKY_COL, skyBrightness);
            reflectedSky = toneMapReinhard(reflectedSky);
            clouds = renderClouds(skyPos, cameraPosition, shadowLitPos, smoothstep(0.0, 0.25, daylight), rainStrength, frameTimeCounter);
            moon = drawMoon(cross(skyPos, moonPos) * 127.0, getMoonPhase(moonPhase), 10.0);

            reflectedSky = mix(reflectedSky, vec3(1.0), getStars(skyPos) * smoothstep(0.2, 0.0, daylight));
            reflectedSky = mix(reflectedSky, MOON_COL * mix(1.0, 0.85, clamp(simplexNoise(cross(skyPos, moonPos).xz / 0.06), 0.0, 1.0)), moon);
            reflectedSky = mix(albedo.rgb, mix(albedo.rgb, mix(reflectedSky, clouds.rgb, clouds.a * 0.65), outdoor), outdoor);
        }
        if (waterFlag > 0.5) {
            albedo.rgb = reflectedSky;
        } else if ((refUV.x < 0 || refUV.x > 1 || refUV.y < 0 || refUV.y > 1 || refUV.z < 0 || refUV.z > 1.0)) {
            albedo.rgb = mix(reflectedSky, albedo.rgb, cosTheta);
        }
    #endif
}

vec4 bloom = vec4(0.0);
if (bloomFlag > 0.5) {
    bloom = vec4(albedo.rgb, 1.0);
}

float reflectance =
#ifdef TERRAIN
    waterFlag > 0.5 || blendFlag > 0.5 || tintFlag > 0.5 ? 1.0 : 0.0;
#else
    0.0;
#endif

#ifdef SHADOW
    if (waterFlag > 0.5 || blendFlag > 0.5) {
        albedo = vec4(0.0);
    }
#endif

    /* DRAWBUFFERS:0245
     * 0 = gcolor
     * 1 = gdepth
     * 2 = gnormal
     * 3 = composite
     * 4 = gaux1
     * 5 = gaux2
     * 6 = gaux3
     * 7 = gaux4
    */
	gl_FragData[0] = albedo; // gcolor
    gl_FragData[1] = vec4((normal + 1.0) * 0.5, 1.0); // gnormal
    gl_FragData[2] = vec4(reflectance, waterFlag, uv1); // gaux1
    gl_FragData[3] = bloom; // gaux2
}
#endif /* defined FRAGMENT */

#if defined VERTEX
attribute vec3 mc_Entity;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform vec3 shadowLightPosition, sunPosition, moonPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 shadowLitPos, sunPos, moonPos;
varying vec3 normal;
varying vec3 viewPos;
varying vec3 relPos;
varying vec3 fragPos;
flat varying float waterFlag;
flat varying float bloomFlag;
flat varying float blendFlag;
flat varying float tintFlag;

#include "utilities/settings.glsl"
#include "utilities/muskRoseShadow.glsl"

void main() {
uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col = gl_Color;

normal = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);

shadowLitPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
sunPos = normalize(mat3(gbufferModelViewInverse) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * moonPosition);

/*
 ** Can't be just "gl_Vertex.xyz" because its behaviour is not compatible
 * with older game versions.
*/
viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

relPos  = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
fragPos = relPos + cameraPosition;

#if defined TERRAIN || defined SHADOW
	waterFlag = int(mc_Entity.x) == 10000 ? 1.0 : 0.0;
    bloomFlag = int(mc_Entity.x) == 10001 ? 1.0 : 0.0;
    blendFlag = int(mc_Entity.x) == 10003 ? 1.0 : 0.0;
    tintFlag  = int(mc_Entity.x) == 10004 ? 1.0 : 0.0;
#else
	waterFlag = 0.0;
    bloomFlag = 0.0;
    blendFlag = 0.0;
    tintFlag  = 0.0;
#endif

// Apply waves
#if defined ENABLE_FOLIAGE_WAVES && (defined TERRAIN || defined SHADOW)
    if (int(mc_Entity.x) == 10002) {
        vec3 wavPos = fragPos;
        vec2 wav = vec2(sin(frameTimeCounter * 2.5 + 2.0 * wavPos.x + wavPos.y), sin(frameTimeCounter * 2.5 + 2.0 * wavPos.z + wavPos.y));
        float wind = sin(frameTimeCounter * 0.5 + wavPos.x * 0.02 + wavPos.y * 0.08 + wavPos.z * 0.1);

        relPos.zx += wav * FOLIAGE_WAVE_STRENGTH * wind * smoothstep(0.7, 1.0, uv1.y);
    }
#endif

    // Equivalent to "ftransform()".
	gl_Position = gl_ProjectionMatrix * (gbufferModelView * vec4(relPos, 1.0));
    #ifdef SHADOW
    	gl_Position.xyz = distort(gl_Position.xyz);
    #endif
}
#endif /* defined VERTEX */