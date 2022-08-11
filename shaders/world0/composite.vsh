#version 120

varying vec2 uv;

void main() {
uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}