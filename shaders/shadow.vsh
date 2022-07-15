#version 120

attribute vec3 mc_Entity;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;

#include "utilities/muskRoseShadow.glsl"

void main() {
uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col = gl_Color;

	gl_Position = ftransform();
	gl_Position.xyz = distort(ftransform().xyz);
}