#if !defined MUSK_ROSE_SSAO_GLSL_INCLUDED
#define MUSK_ROSE_SSAO_GLSL_INCLUDED 1

#define ENABLE_SSAO

const vec2 occlusionSamples[16] = vec2[16](
	  vec2(-0.220147, 0.976896),
	  vec2(-0.735514, 0.693436),
	  vec2(-0.200476, 0.310353),
	  vec2( 0.180822, 0.454146),
	  vec2( 0.292754, 0.937414),
	  vec2( 0.564255, 0.207879),
	  vec2( 0.178031, 0.024583),
	  vec2( 0.613912,-0.205936),
	  vec2(-0.385540,-0.070092),
	  vec2( 0.962838, 0.378319),
	  vec2(-0.886362, 0.032122),
	  vec2(-0.466531,-0.741458),
	  vec2( 0.006773,-0.574796),
	  vec2(-0.739828,-0.410584),
	  vec2( 0.590785,-0.697557),
	  vec2(-0.081436,-0.963262));

/*
 ** Generate SSAO based on SSDO by Yuriy O'Donnell.
 ** See: https://github.com/kayru/dssdo
*/
float getSSAO(const vec3 viewPos, const mat4 projInv, const vec2 uv, const float aspectRatio, const sampler2D depthTex) {
	#ifdef ENABLE_SSAO
		const int samples = occlusionSamples.length();
		const float aoWeight = 1.0;
		const float bias = 0.02;
		
		vec3 normal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
		float ssao = 0.0;
		float radius = 0.03 / (viewPos.z - bias);

		for (int i = 0; i < samples; i++) {
			vec2 offset = length(occlusionSamples[i]) * radius * vec2(1.0, aspectRatio) * normalize(occlusionSamples[i]);

			vec3 t0 = getViewPos(projInv, uv + offset, texture2D(depthTex, uv + offset).r).xyz;
			t0.z -= bias;

			float dist = length(t0.xyz - viewPos.xyz);

			float attenuation = 1.0 - clamp(dist * 0.6, 0.0, 1.0);
			float dp = dot(normal, (t0.xyz - viewPos.xyz) / dist);

			attenuation = sqrt(max(dp, 0.0)) * attenuation * attenuation * step(0.1, dp);
			ssao += attenuation * (aoWeight / float(samples));
		}

		return ssao;
	#else
		return 0.0;
	#endif
}

#endif /* !defined MUSK_ROSE_SSAO_GLSL_INCLUDED */