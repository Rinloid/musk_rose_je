#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex1;
uniform float centerDepthSmooth;
uniform float viewWidth, viewHeight;

varying vec2 uv;

mat2 getRotationMatrix(const float angle) {
	return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

const float centerDepthHalflife = 2.0; // [0.0 1.0 2.0 3.0 4.0 5.0]

#define ENABLE_DOF

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
float depth = texture2D(depthtex1, uv).r;

/*
 ** Apply Depth of Field effect.
 ** See also: https://github.com/Rinloid/dof-minecraft
*/

float centreDepth = centerDepthSmooth;
vec2 screenResolution = vec2(viewWidth, viewHeight);

vec2 pixelSize = 1.0 / screenResolution;
float unfocused = smoothstep(0.0, 0.01, abs(depth - centreDepth));
vec3 blurred = vec3(0.0, 0.0, 0.0);

const int steps = 6;

#if defined ENABLE_DOF
	if (unfocused > 0.0) {
		for (int i = -steps; i < steps; i++) {
			for (int j = -steps; j < steps; j++) {
				vec2 offset = vec2(i, j) * pixelSize;
				offset *= getRotationMatrix(float(steps * 2 * steps * 2));

				blurred += texture2D(gcolor, uv + offset * unfocused).rgb;
			}
		} blurred /= float(steps * 2 * steps * 2);

		albedo = blurred;
	}
#endif


    /* DRAWBUFFERS:0
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