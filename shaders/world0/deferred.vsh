#version 120

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform vec3 sunPosition, moonPosition, shadowLightPosition;

varying vec2 uv;
varying vec3 sunPos, moonPos, shadowLitPos;

void main() {
uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
sunPos       = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * sunPosition);
moonPos      = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * moonPosition);
shadowLitPos = normalize(mat3(gbufferModelViewInverse) * mat3(gl_ModelViewMatrix) * shadowLightPosition);

	gl_Position = ftransform();
}