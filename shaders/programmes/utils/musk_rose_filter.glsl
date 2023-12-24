#if !defined MUSK_ROSE_FILTER_GLSL_INCLUDED
#define MUSK_ROSE_FILTER_GLSL_INCLUDED

float getLuma(const vec3 col) {
	return dot(col, vec3(0.22, 0.707, 0.071));
}

vec3 brighten(const vec3 col) {
    return col + 1.0 - max(col.r, max(col.g, col.b));
}

vec4 brighten(const vec4 col) {
    return vec4(col.rgb + 1.0 - max(col.r, max(col.g, col.b)), col.a);
}

vec3 toneMapReinhard(const vec3 color) {
	vec3 col = color * color;
    vec3 exposure = col / (col + 1.0);
	vec3 result = mix(col / (getLuma(col) + 1.0), exposure, exposure);

    return result;
}

/* 
** Uncharted 2 tonemapping
** See: http://filmicworlds.com/blog/filmic-tonemapping-operators/
*/
vec3 uncharted2TonemapFilter(const vec3 col) {
	const float A = 0.015; // Shoulder strength
	const float B = 0.500; // Linear strength
	const float C = 0.100; // Linear angle
	const float D = 0.010; // Toe strength
	const float E = 0.020; // Toe numerator
	const float F = 0.300; // Toe denominator

	return ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
}
vec3 uncharted2Tonemap(const vec3 col, const float whiteLevel, const float exposure) {
	vec3 curr = uncharted2TonemapFilter(col * exposure);
	vec3 whiteScale = 1.0 / uncharted2TonemapFilter(vec3(whiteLevel, whiteLevel, whiteLevel));
	vec3 color = curr * whiteScale;

	return color;
}

vec3 hdrExposure(const vec3 col, const float over, const float under) {
	return mix(col / over, col * under, col);
}

#endif /* !defined MUSK_ROSE_FILTER_GLSL_INCLUDED */