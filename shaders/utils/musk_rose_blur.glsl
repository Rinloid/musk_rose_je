#if !defined MUSK_ROSE_BLUR_GLSL_INCLUDED
#define MUSK_ROSE_BLUR_GLSL_INCLUDED

#define BLUR_HORIZONTAL 1
#define BLUR_VERTICAL 2

float curve(const float x, const float y) {
	return y / (x * x + y);
}

mat2 getRotationMatrix(const float angle) {
	return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

vec3 getBlur(const sampler2D image, const vec2 uv, const vec2 pixelSize, const int steps, const float blurStrength) {
	vec3 result = vec3(0.0);
	#ifdef ENABLE_BLUR
		vec2 offset = 1.0 / textureSize(image, 0);
		offset *= blurStrength;
		
		float weight = 0.0;
		for (int i = 0; i < steps; i++) {
			weight = curve(i / steps, 0.4);
#		if ENABLE_BLUR == BLUR_HORIZONTAL
			result += texture(image, uv + vec2(offset.x * float(i + 1), 0.0)).rgb * weight;
			result += texture(image, uv - vec2(offset.x * float(i + 1), 0.0)).rgb * weight;
#		elif ENABLE_BLUR == BLUR_VERTICAL
			result += texture(image, uv + vec2(0.0, offset.y * float(i + 1))).rgb * weight;
			result += texture(image, uv - vec2(0.0, offset.y * float(i + 1))).rgb * weight;
#		endif
		} result /= float(steps * 2);
	#endif

	return result;
}

#endif /* !MUSK_ROSE_BLUR_GLSL_INCLUDED */