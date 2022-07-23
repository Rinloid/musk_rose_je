#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;

void main() {
vec4 albedo = texture2D(texture, uv0);

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
}