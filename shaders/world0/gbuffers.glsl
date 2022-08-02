#if defined GBUFFERS_FRAGMENT
uniform sampler2D texture;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth, viewHeight;
uniform vec4 entityColor;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying mat3 tbnMatrix;

float fogify(const float x, const float w) {
	return w / (x * x + w);
}

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
        gl_FragData[2] = vec4(uv1, 0.0, 0.0); // gaux1
#   else
        /* DRAWBUFFERS:0
        * 0 = everything
        * 1 = translucent
        */
        gl_FragData[0] = albedo; // everything
#   endif
}
#elif defined GBUFFERS_VERTEX /* defined GBUFFERS_FRAGMENT */
attribute vec4 at_tangent;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 normal;
varying mat3 tbnMatrix;

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
tangent   = normalize(gl_NormalMatrix * at_tangent.xyz);
binormal  = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
normal    = normalize(gl_NormalMatrix * gl_Normal);
tbnMatrix = transpose(mat3(tangent, binormal, normal));

	gl_Position = ftransform();
#   if defined GBUFFERS_SHADOW
        gl_Position.xyz = distort(gl_Position.xyz);
#   endif
}
#endif /* defined GBUFFERS_FRAGMENT */