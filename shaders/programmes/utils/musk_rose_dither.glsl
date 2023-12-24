#if !defined MUSK_ROSE_DITHER_INCLUDED
#define MUSK_ROSE_DITHER_INCLUDED

/*
 ** Bayer dither by Jodie
*/
float bayerX2(vec2 a) {
	return fract(dot(floor(a), vec2(0.5, floor(a).y * 0.75)));
}

#define bayerX4(a)  (bayerX2 (0.5 * (a)) * 0.25 + bayerX2(a))
#define bayerX8(a)  (bayerX4 (0.5 * (a)) * 0.25 + bayerX2(a))
#define bayerX16(a) (bayerX8 (0.5 * (a)) * 0.25 + bayerX2(a))
#define bayerX32(a) (bayerX16(0.5 * (a)) * 0.25 + bayerX2(a))
#define bayerX64(a) (bayerX32(0.5 * (a)) * 0.25 + bayerX2(a))

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

#endif /* MUSK_ROSE_DITHER_INCLUDED */