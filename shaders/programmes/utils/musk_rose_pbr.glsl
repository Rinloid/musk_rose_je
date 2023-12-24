#if !defined MUSK_ROSE_PBR_INCLUDED
#define MUSK_ROSE_PBR_INCLUDED

vec3 getFresnelSchlick(const vec3 V, const vec3 N, const vec3 F0) {
    float cosTheta = clamp(1.0 - max(0.0, dot(V, N)), 0.0, 1.0);

    return clamp(F0 + (1.0 - F0) * cosTheta * cosTheta * cosTheta * cosTheta * cosTheta, 0.0, 1.0);
}

// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
vec3 getEnvironmentBRDF(const vec3 V, const vec3 N, const float R, const vec3 F0) {
	vec4 r = R * vec4(-1.0, -0.0275, -0.572,  0.022) + vec4(1.0, 0.0425, 1.04, -0.04);
	vec2 AB = vec2(-1.04, 1.04) * min(r.x * r.x, exp2(-9.28 * max(0.0, dot(V, N)))) * r.x + r.y + r.zw;

	return F0 * AB.x + AB.y;
}

float getVisibleGGX(const vec3 V, const vec3 L, const vec3 N, const float R) {
	float dotLN = max(0.0, dot(L, N));
	float dotVN = max(0.0, dot(V, N));

	float gv = dotLN * sqrt(dotVN * (dotVN - dotVN * R * R) + R * R);
	float gl = dotVN * sqrt(dotLN * (dotLN - dotLN * R * R) + R * R);
	
	return 0.5 / max(0.001, gv + gl);
}

float getDistributionGGX(const vec3 V, const vec3 L, const vec3 N, const float R) {
	vec3 H = normalize(V + L);
	float dotHN = max(0.0, dot(H, N));
	float denominator = (dotHN * R * R - dotHN) * dotHN + 1.0;
	
	return (R * R) / (3.14159265359 * denominator * denominator);
}

float getGeometrySchlickGGX(const float n, const float R) {
    float k = ((R + 1.0) * (R + 1.0)) / 8.0;
	
    return n / (n * (1.0 - k) + k);
}
float getGeometrySmith(const vec3 V, const vec3 L, const vec3 N, const float R) {
    float dotVN = max(dot(V, N), 0.0);
    float dotLN = max(dot(L, N), 0.0);

    return getGeometrySchlickGGX(dotVN, R) * getGeometrySchlickGGX(dotLN, R);
}

vec3 getSpecular(const vec3 V, const vec3 L, const vec3 N, const float R, const vec3 F0) {
	vec3 H = normalize(V + L);
	
	float dotVN = max(dot(V, N), 0.0);
    float dotLN = max(dot(L, N), 0.0);

	float GGX = getDistributionGGX(V, L, N, R) * getVisibleGGX(V, L, N, R);
	float G = getGeometrySmith(V, L, N, R);
	vec3 F = getFresnelSchlick(H, N, F0);

	return (GGX * G * F) / max(0.001, 4.0 * dotVN * dotLN);
}

#endif /* MUSK_ROSE_PBR_INCLUDED */