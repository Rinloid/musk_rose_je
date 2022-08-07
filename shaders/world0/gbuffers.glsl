#if defined GBUFFERS_FRAGMENT
uniform sampler2D texture;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;
uniform vec4 entityColor;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 sunPos, moonPos, shadowLightPos;
varying vec3 viewPos;
varying vec3 relPos;
varying vec3 fragPos;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying mat3 tbnMatrix;
flat varying float waterFlag;

float fogify(const float x, const float w) {
	return w / (x * x + w);
}

// #define DEBUG_WHITE

#include "/utilities/muskRoseWater.glsl"
#include "/utilities/muskRoseSky.glsl"

void main() {
vec4 albedo =
#if defined GBUFFERS_BASIC
    col;
#elif defined GBUFFERS_SKY
    vec4(vec3(0.0), 1.0);
#else
    texture2D(texture, uv0) * col;
#endif
vec2 uvp = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;
if (waterFlag > 0.5) {
    worldNormal = normalize(getWaterWavNormal(fragPos.xz, frameTimeCounter) * tbnMatrix);
    worldNormal = mat3(gbufferModelViewInverse) * worldNormal;
}
vec3 skyPos = normalize(relPos);
float cosTheta = abs(dot(normalize(relPos), worldNormal));
float daylight = max(0.0, sin(sunPos.y));
float skyBrightness = mix(0.7, 2.0, smoothstep(0.0, 0.1, daylight));
float blendFlag = 0.0;

#if defined GBUFFERS_ENTITIES
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif

#if defined GBUFFERS_SKY
    if (col.a > 0.5) {
        albedo.rgb = col.rgb;
    } else {
        vec4 pos = vec4(uvp * 2.0 - 1.0, 1.0, 1.0);
        pos = gbufferProjectionInverse * pos;
        float upDot = max(0.0, dot(pos.xyz, gbufferModelView[1].xyz));

        albedo.rgb = mix(skyColor, fogColor, fogify(upDot, 0.01));
    }
#endif

if (waterFlag > 0.5) {
    albedo = vec4(0.0, 0.2, 0.3, 0.1);
}

#if defined GBUFFERS_WATER
    blendFlag = 1.0;
    
    albedo.a = mix(1.0, albedo.a, cosTheta);
#endif

#if defined DEBUG_WHITE
    albedo.rgb = vec3(1.0);
#endif

#   if !defined GBUFFERS_SHADOW
        /* DRAWBUFFERS:024
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
        gl_FragData[1] = vec4((worldNormal + 1.0) * 0.5, 1.0); // gnormal
        gl_FragData[2] = vec4(uv1, blendFlag, 1.0); // gaux1
#   else
        /* DRAWBUFFERS:0
        * 0 = everything
        * 1 = translucent
        */
        gl_FragData[0] = albedo; // everything
#   endif
}
#endif /* defined GBUFFERS_FRAGMENT */

#if defined GBUFFERS_VERTEX
attribute vec4 at_tangent;
attribute vec3 mc_Entity;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform vec3 sunPosition, moonPosition, shadowLightPosition;
uniform vec3 cameraPosition;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 sunPos, moonPos, shadowLightPos;
varying vec3 viewPos;
varying vec3 relPos;
varying vec3 fragPos;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying mat3 tbnMatrix;
flat varying float waterFlag;

#include "/utilities/muskRoseShadow.glsl"

void main() {
uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col =
#if defined GBUFFERS_SKY
    vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
#else
    gl_Color;
#endif
sunPos = normalize(mat3(gbufferModelViewInverse) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * moonPosition);
shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
relPos  = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
fragPos = relPos + cameraPosition;
tangent   = normalize(gl_NormalMatrix * at_tangent.xyz);
binormal  = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
normal    = normalize(gl_NormalMatrix * gl_Normal);
tbnMatrix = transpose(mat3(tangent, binormal, normal));
waterFlag =
#if defined GBUFFERS_WATER
    int(mc_Entity.x) == 10000 ? 1.0 : 0.0;
#else
    0.0;
#endif

	gl_Position = ftransform();
#   if defined GBUFFERS_SHADOW
        gl_Position.xyz = distort(gl_Position.xyz);
#   endif
}
#endif /* defined GBUFFERS_VERTEX */