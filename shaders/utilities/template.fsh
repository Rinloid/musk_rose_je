#version 120

uniform sampler2D gcolor;

varying vec2 uv;

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;

    /* DRAWBUFFERS:0 */
    /*
     * 0 = gcolor
     * 1 = gdepth
     * 2 = gnormal
     * 3 = composite
     * 4 = gaux1
     * 5 = gaux2
     * 6 = gaux3
     * 7 = gaux4
    */
	gl_FragData[0] = vec4(albedo, 1.0); // gcolor
}