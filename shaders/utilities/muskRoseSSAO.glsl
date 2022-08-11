#if !defined SSAO_INCLUDED
#define SSAO_INCLUDED 1

#define ENABLE_AO

const vec2 occlusionSamples[8] = vec2[8] (
    vec2(-0.48945, -0.358),
	vec2(-0.17171, 0.6272),
	vec2(-0.47094, -0.017),
	vec2(-0.99106, 0.0383),
	vec2(-0.21012, 0.2034),
	vec2(-0.78895, -0.567),
	vec2(-0.10377, -0.158),
	vec2(-0.57284, 0.3416)
);

/*
 ** Generate SSAO based on SSDO by Yuriy O'Donnell.
 ** See: https://github.com/kayru/dssdo
*/
float getSSAO(const vec3 viewPos, const mat4 projInv, const vec2 uv, const float aspectRatio, const sampler2D depthTex) {
	#if defined ENABLE_AO
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

#endif /* !defined SSAO_INCLUDED */