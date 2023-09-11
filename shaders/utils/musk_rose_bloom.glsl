#if !defined MUSK_ROSE_BLOOM_GLSL_INCLUDED
#define MUSK_ROSE_BLOOM_GLSL_INCLUDED

#define ENABLE_BLOOM

vec3 getPreBloomBlur(const sampler2D bloomSampler, const vec2 uv) {
	const int steps = 8;
	const float stepSize = 1.0; 

	vec3 result = vec3(0.0, 0.0, 0.0);

	#ifdef ENABLE_BLOOM
		for (int i = 0; i < steps; i++) {
			result += textureLod(bloomSampler, uv, float(i) * stepSize).rgb;
		} result /= float(steps);
	#endif

	return result;
}

#define BLUR_HORIZONTAL 1
#define BLUR_VERTICAL 2

float curve(const float x, const float y) {
	return y / (x * x + y);
}

vec3 getBloomBlur(const sampler2D bloomSampler, const vec2 uv) {
	const int steps = 12;
	const float blurStrength = 2.0;
	vec3 result = vec3(0.0);
	#ifdef ENABLE_BLOOM
		#ifdef ENABLE_BLUR
			vec2 offset = 1.0 / textureSize(bloomSampler, 0);
			offset *= blurStrength;
			
			float weight = 0.0;
			for (int i = 0; i < steps; i++) {
				weight = curve(i / steps, 0.5);
#			if ENABLE_BLUR == BLUR_HORIZONTAL
				result += textureLod(bloomSampler, uv + vec2(offset.x * float(i + 1), 0.0), 0.0).rgb * weight;
				result += textureLod(bloomSampler, uv - vec2(offset.x * float(i + 1), 0.0), 0.0).rgb * weight;
#			elif ENABLE_BLUR == BLUR_VERTICAL
				result += textureLod(bloomSampler, uv + vec2(0.0, offset.y * float(i + 1)), 0.0).rgb * weight;
				result += textureLod(bloomSampler, uv - vec2(0.0, offset.y * float(i + 1)), 0.0).rgb * weight;
#			endif
			} result /= float(steps * 2);
		#endif
	#endif

	return result;
}

#endif /* !defined MUSK_ROSE_BLOOM_GLSL_INCLUDED */