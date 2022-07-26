#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex1;
uniform sampler2D gaux2;
uniform float centerDepthSmooth;
uniform float viewWidth, viewHeight;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

varying vec2 uv;

#include "utilities/muskRoseBlur.glsl"

#define ENABLE_DOF
#define ENABLE_BLOOM

const float centerDepthHalflife = 2.0; // [0.0 1.0 2.0 3.0 4.0 5.0]
const int steps = 6;
const int bloomSteps = 4;

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
float depth = texture2D(depthtex1, uv).r;
vec4 bloom = texture2D(gaux2, uv);
vec2 screenResolution = vec2(viewWidth, viewHeight);
vec2 pixelSize = 1.0 / screenResolution;
float centreDepth = centerDepthSmooth;
float unfocused = smoothstep(0.0, 0.05, abs(depth - centreDepth));

vec3 blurred = vec3(0.0);

#ifdef ENABLE_DOF
	if (unfocused > 0.0 && depth > 0.8) {
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

#ifdef ENABLE_BLOOM
	float brightness = dot(bloom.rgb, vec3(0.22, 0.707, 0.071));
	brightness = brightness * brightness * 3.0;

	if (unfocused > 0.0 && depth > 0.8) {
		for (int i = -bloomSteps; i < bloomSteps; i++) {
			for (int j = -bloomSteps; j < bloomSteps; j++) {
				vec2 offset = vec2(i, j) * pixelSize;
				offset *= getRotationMatrix(float(bloomSteps * 2 * bloomSteps * 2));

				blurred += texture2D(gaux2, uv + offset * 5.0).rgb * brightness;
			}
		} blurred /= float(bloomSteps * 2 * bloomSteps * 2);

		albedo += blurred;
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