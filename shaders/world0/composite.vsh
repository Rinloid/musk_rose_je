#version 120

attribute vec4 at_tangent;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform vec3 shadowLightPosition, sunPosition, moonPosition;

varying vec2 uv;
varying vec3 shadowLitPos, sunPos, moonPos;

void main() {
uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
shadowLitPos = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * shadowLightPosition);
sunPos = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * sunPosition);
moonPos = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * moonPosition);

	gl_Position = ftransform();
}