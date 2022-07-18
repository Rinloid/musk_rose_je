#if defined FRAGMENT
uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D gaux1;
uniform float viewWidth, viewHeight;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec4 entityColor;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
varying vec3 normal;
varying vec3 viewPos;
varying vec3 relPos;
varying vec3 fragPos;
flat varying float waterFlag;
flat varying float bloomFlag;

void main() {
vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
vec4 albedo = texture2D(texture, uv0);
if (abs(col.r - col.g) > 0.001 || abs(col.g - col.b) > 0.001) {
    albedo.rgb *= normalize(col.rgb);
}
#ifdef ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif
vec3 worldNormal = normal;

if (waterFlag > 0.5) {
    float cosTheta = abs(dot(normalize(relPos), worldNormal));

    albedo.rgb = vec3(0.0, 0.15, 0.3);
    albedo.a   = mix(1.0, 0.1, cosTheta);
}

vec4 bloom = vec4(0.0);
if (bloomFlag > 0.5) {
    bloom = vec4(albedo.rgb, 1.0);
}

float reflectance = waterFlag > 0.5 ? 1.0 : 0.0;

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
    gl_FragData[1] = vec4(worldNormal, reflectance); // gnormal
    gl_FragData[2] = vec4(uv0, uv1); // gaux1
    gl_FragData[3] = bloom; // gaux2
}
#endif /* defined FRAGMENT */

#if defined VERTEX
attribute vec4 at_tangent;
attribute vec3 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;
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

viewPos  = (gl_ModelViewMatrix * gl_Vertex).xyz;
relPos  = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
fragPos = relPos + cameraPosition;

#ifndef ENTITY
	waterFlag = int(mc_Entity.x) == 10000 ? 1.0 : 0.0;
    bloomFlag = int(mc_Entity.x) == 10001 ? 1.0 : 0.0;
#else
	waterFlag = 0.0;
#endif

	gl_Position = ftransform();
}
#endif /* defined VERTEX */