#if !defined HASH_INCLUDED
#define HASH_INCLUDED 1

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
	vec3 p = fract(vec3(pos.xyx) * sc);
    p += dot(p, p.yzx + b);

    return fract((p.xx + p.yz) * p.zy);
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

#endif /* !defined HASH_INCLUDED */