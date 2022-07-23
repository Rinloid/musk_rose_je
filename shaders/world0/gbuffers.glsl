#if defined FRAGMENT
uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D gaux1;
uniform float viewWidth, viewHeight;
uniform float rainStrength;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec4 entityColor;
uniform int isEyeInWater;

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

void main() {
vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
vec4 albedo = texture2D(texture, uv0);
if (abs(col.r - col.g) > 0.001 || abs(col.g - col.b) > 0.001) {
    albedo.rgb *= normalize(col.rgb);
}
#ifdef ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif

float outdoor = smoothstep(0.5, 0.6, uv1.y);
float daylight = max(0.0, sin(sunPos.y));
float duskDawn = min(smoothstep(0.0, 0.3, daylight), smoothstep(0.5, 0.3, daylight));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));

if (waterFlag > 0.5) {
    vec3 worldNormal = normalize(getWaterWavNormal(fragPos.xz, frameTimeCounter) * getTBNMatrix(normal));
    float cosTheta = abs(dot(normalize(relPos), normal));

    albedo.rgb = vec3(0.0, 0.15, 0.3);
    albedo.a = 1.0;

    if (isEyeInWater == 1) {
        albedo.a = 0.5;
    }

	vec3 reflectedSky = vec3(0.0);
	vec4 clouds = vec4(0.0);
	
	if (!bool(1.0 - outdoor) && isEyeInWater == 0) {
		reflectedSky = getAtmosphere(reflect(normalize(relPos), worldNormal), shadowLitPos, vec3(0.4, 0.65, 1.0), skyBrightness);
		reflectedSky = toneMapReinhard(reflectedSky);
		clouds = renderClouds(reflect(normalize(relPos), worldNormal), cameraPosition, shadowLitPos, smoothstep(0.0, 0.25, daylight), rainStrength, frameTimeCounter);

		reflectedSky = mix(albedo.rgb, mix(albedo.rgb, mix(reflectedSky, clouds.rgb, clouds.a * 0.65), outdoor), 1.0 - (1.0 - outdoor));
	}

    albedo.rgb = reflectedSky;
}

vec4 bloom = vec4(0.0);
if (bloomFlag > 0.5) {
    bloom = vec4(albedo.rgb, 1.0);
}

float reflectance =
#ifdef TERRAIN
    waterFlag > 0.5 ? 1.0 : 0.0;
#else
    0.0;
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
    gl_FragData[1] = vec4(normal, reflectance); // gnormal
    gl_FragData[2] = vec4(uv0, uv1); // gaux1
    gl_FragData[3] = bloom; // gaux2
}
#endif /* defined FRAGMENT */

#if defined VERTEX
attribute vec4 at_tangent;
attribute vec3 mc_Entity;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform vec3 shadowLightPosition, sunPosition, moonPosition;
uniform vec3 cameraPosition;

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

void main() {
uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col = gl_Color;

normal = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);

shadowLitPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
sunPos = normalize(mat3(gbufferModelViewInverse) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * moonPosition);

viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
relPos  = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
fragPos = relPos + cameraPosition;

#ifdef TERRAIN
	waterFlag = int(mc_Entity.x) == 10000 ? 1.0 : 0.0;
    bloomFlag = int(mc_Entity.x) == 10001 ? 1.0 : 0.0;
#else
	waterFlag = 0.0;
#endif

	gl_Position = ftransform();
}
#endif /* defined VERTEX */