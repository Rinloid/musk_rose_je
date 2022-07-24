#if !defined BLUR_INCLUDED
#define BLUR_INCLUDED 1

#define BLUR_QUALITY 24 // [4 8 12 24 32 64 128 256 512]

mat2 getRotationMatrix(const float angle) {
	return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

/*
 ** Based on Bokeh Disc by David Hoskins.
 ** See: https://www.shadertoy.com/view/4d2Xzw
*/
vec3 blur(const sampler2D tex, const vec2 uv, const float radius) {
	const int blurSteps = BLUR_QUALITY;

	vec3 acc = vec3(0.0);
	vec3 div = acc;
	float r = 1.0;
    vec2 vangle = vec2(0.0, radius * 0.01 / sqrt(float(blurSteps)));
    
	for (int i = 0; i < blurSteps; i++) {  
        r += 1.0 / r;

	    vangle = getRotationMatrix((3.0 - sqrt(5.0)) * 3.14) * vangle;
        vec3 col = texture2D(tex, uv + (r - 1.0) * vangle).rgb;
		vec3 blur = col * col * col * col;
		
		acc += col * blur;
		div += blur;
	}

    return acc / div;
}

#endif /* !defined BLUR_INCLUDED */