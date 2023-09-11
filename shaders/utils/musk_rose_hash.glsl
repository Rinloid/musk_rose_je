#if !defined MUSK_ROSE_NOISE_GLSL_INCLUDED
#define MUSK_ROSE_NOISE_GLSL_INCLUDED

uniform sampler2D colortex15, colortex14;

#define HASH_TEXTURE_RESOLUTION 32
#define VORONOI_TEXTURE_RESOLUTION 1024

float hashTex(const vec2 pos) {
    return texture(colortex15, pos / float(HASH_TEXTURE_RESOLUTION)).r;
}

float getWaterNoise(const vec2 pos) {
	return 1.0 - texture(colortex14, pos / float(VORONOI_TEXTURE_RESOLUTION)).r;
}

float getCloudNoise(const vec2 pos) {
	return texture(colortex14, pos / float(VORONOI_TEXTURE_RESOLUTION)).r;
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

#endif /* !defined MUSK_ROSE_NOISE_GLSL_INCLUDED */