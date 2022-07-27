#version 120

uniform sampler2D lightmap;

varying vec2 uv1;
varying vec4 col;

void main() {
vec4 albedo = col * texture2D(lightmap, uv1);

    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo; //gcolor
}