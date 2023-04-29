#if !defined MUSK_ROSE_FOG_GLSL_INCLUDED
#define MUSK_ROSE_FOG_GLSL_INCLUDED

float getFog(const vec2 control, const vec3 pos) {
	float base = sqrt(log(1.0/0.015)) / (control.y - control.x);
	float dist = max(0.0, length(-pos) - control.x);

    float fogFactor = 1.0 / exp(pow(dist * base, 2.0));
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    return 1.0 - fogFactor;
}

#endif /* !defined MUSK_ROSE_FOG_GLSL_INCLUDED */