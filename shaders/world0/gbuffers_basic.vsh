#version 120

varying vec2 uv1;
varying vec4 col;

void main() {
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col = gl_Color;

    gl_Position = ftransform();
}