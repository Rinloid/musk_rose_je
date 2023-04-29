#if !defined MUSK_ROSE_NOISE_GLSL_INCLUDED
#define MUSK_ROSE_NOISE_GLSL_INCLUDED

uniform sampler2D colortex15;

float getWaterNoise(const vec2 pos) {
	return texture(colortex15, pos).r;
}

/*
 ** Hash without sine modded by Rin
 ** Original author: David Hoskins (MIT License)
 ** See: https://www.shadertoy.com/view/4djSRW
*/

const vec3 sc = vec3(0.1031, 0.1030, 0.0973);
const float b = 33.33;

float hash11(const float pos) {
    float p = fract(pos * sc.x);
    p *= p + b;
    p *= p + p;

    return fract(p);
}
float hash12(const vec2 pos) {
	vec3 p = fract(vec3(pos.xyx) * sc.x);
    p += dot(p, p.yzx + b);

    return fract((p.x + p.y) * p.z);
}
float hash13(const vec3 pos) {
	vec3 p = fract(pos * sc.x);
    p += dot(p, p.zyx + b);

    return fract((p.x + p.y) * p.z);
}
vec2 hash21(const float pos) {
	vec3 p = fract(vec3(pos) * sc);
	p += dot(p, p.yzx + b);

    return fract((p.xx + p.yz) * p.zy);

}
vec2 hash22(const vec2 pos) {
	vec2 p = vec2(dot(pos, vec2(127.1, 311.7)),
			      dot(pos, vec2(269.5, 183.3)));

	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
vec2 hash23(const vec3 pos) {
	vec3 p = fract(pos * sc);
    p += dot(p, p.yzx + b);

    return fract((p.xx + p.yz) * p.zy);
}
vec3 hash31(const float pos) {
   vec3 p = fract(vec3(pos) * sc);
   p += dot(p, p.yzx + b);

   return fract((p.xxy + p.yzz) * p.zyx); 
}
vec3 hash32(const vec2 pos) {
	vec3 p = fract(vec3(pos.xyx) * sc);
    p += dot(p, p.yxz + b);

    return fract((p.xxy + p.yzz) * p.zyx);
}
vec3 hash33(const vec3 pos) {
	vec3 p = fract(pos * sc);
    p += dot(p, p.yxz + b);

    return fract((p.xxy + p.yxx) * p.zyx);
}

/*
 ** Simplex Noise modded by Rin
 ** Original author: Ashima Arts (MIT License)
 ** See: https://github.com/ashima/webgl-noise
 **      https://github.com/stegu/webgl-noise
*/
vec2 mod289(vec2 x) {
    return x - floor(x * 1.0 / 289.0) * 289.0;
}
vec3 mod289(vec3 x) {
    return x - floor(x * 1.0 / 289.0) * 289.0;
}
vec3 permute289(vec3 x) {
    return mod289((x * 34.0 + 1.0) * x);
}
float getSimplexNoise(vec2 v) {
    const vec4 c = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);

    vec2 i  = floor(v + dot(v, c.yy));
    vec2 x0 = v -   i + dot(i, c.xx);

    vec2 i1  = x0.x > x0.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + c.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute289(permute289(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m *= m * m * m;

    vec3 x  = 2.0 * fract(p * c.www) - 1.0;
    vec3 h  = abs(x) - 0.5;
    vec3 ox = round(x);
    vec3 a0 = x - ox;

    m *= inversesqrt(a0 * a0 + h * h);

    vec3 g;
    g.x  = a0.x  * x0.x   + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    
    return 130.0 * dot(m, g);
}


float getCloudNoise(const vec2 pos, const float rainLevel) {
	return smoothstep(mix(0.4, 0.0, rainLevel), 1.0, texture(colortex15, pos).g);
}

#endif /* !defined MUSK_ROSE_NOISE_GLSL_INCLUDED */