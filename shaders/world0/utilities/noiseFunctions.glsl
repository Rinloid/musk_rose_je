#if !defined NOISE_INCLUDED
#define NOISE_INCLUDED 1

/*
 ** Hash from "Hahs without Sine"
 ** Author: David Hoskins
 ** See: https://www.shadertoy.com/view/4djSRW
*/
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);

    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3) {
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);

    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

/*
 ** Simplex Noise modified by Rin
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
float simplexNoise(vec2 v) {
    const vec4 c = vec4(
        0.211324865405187,   // (3.0-sqrt(3.0))/6.0
        0.366025403784439,   // 0.5*(sqrt(3.0)-1.0)
       -0.577350269189626,   // -1.0 + 2.0 * C.x
        0.024390243902439);  // 1.0 / 41.0

    // First corner
    vec2 i  = floor(v + dot(v, c.yy));
    vec2 x0 = v -   i + dot(i, c.xx);

    // Other corners
    vec2 i1  = x0.x > x0.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + c.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p =
        permute289(
            permute289(
                i.y + vec3(0.0, i1.y, 1.0)
                ) + i.x + vec3(0.0, i1.x, 1.0)
            );

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    /*
     ** Gradients: 41 points uniformly over a line, mapped onto a
     * diamond.  The ring size 17 * 17 = 289 is close to a multiple of
     * 41 (41 * 7 = 287)
    */
    vec3 x  = 2.0 * fract(p * c.www) - 1.0;
    vec3 h  = abs(x) - 0.5;
    vec3 ox = round(x);
    vec3 a0 = x - ox;

    /*
     ** Normalise gradients implicitly by scaling m.
    */
    m *= inversesqrt(a0 * a0 + h * h);

    /*
     ** Compute final noise value at P.
    */
    vec3 g;
    g.x  = a0.x  * x0.x   + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    
    return 130.0 * dot(m, g);
}

#endif /* !defined NOISE_INCLUDED */