/*
 ** Shadow distortion based on Shadow Tutorial.  Visit shaderLABS for details.
 ** https://discord.gg/KJ2SXNkKqS
*/

float cubeLength(vec2 v) {
	return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
}

float getDistortFactor(vec2 v) {
	return cubeLength(v) + 0.05;
}

vec3 distort(vec3 v, float factor) {
	return vec3(v.xy / factor, v.z * 0.5);
}

vec3 distort(vec3 v) {
	return distort(v, getDistortFactor(v.xy));
}

const vec2[28] shadowSamples = vec2[28] (
    vec2(-0.5337560, 0.5918049),
    vec2(-0.5887652, 0.2827983),
    vec2(-0.1112829, 0.8347653),
    vec2(-0.1763154, 0.4841528),
    vec2(0.14189000, 0.3237082),
    vec2(0.28009290, 0.9120663),
    vec2(0.10938630, 0.6212762),
    vec2(-0.9064262, -0.118388),
    vec2(-0.6078327, -0.178559),
    vec2(-0.3574080, 0.1051248),
    vec2(0.65279020, 0.5192569),
    vec2(0.09694252, 0.0323036),
    vec2(-0.6742220, -0.726061),
    vec2(-0.2918845, -0.496468),
    vec2(-0.7958741, -0.442926),
    vec2(-0.1453472, -0.204167),
    vec2(0.48981410, 0.1773323),
    vec2(0.92706070, 0.3427289),
    vec2(0.28210470, -0.219097),
    vec2(-0.8921345, 0.2215670),
    vec2(0.77614340, -0.486889),
    vec2(0.75916190, -0.160456),
    vec2(0.21845470, -0.729269),
    vec2(-0.3362600, -0.881528),
    vec2(-0.8542173, 0.5196956),
    vec2(0.03850133, -0.990621),
    vec2(0.50871050, -0.731712),
    vec2(0.08914156, -0.438681)
);