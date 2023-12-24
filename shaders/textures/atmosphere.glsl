// Run this shader on: https://thebookofshaders.com/edit.php

precision 
#ifdef GL_ES
    highp 
#else
    mediump 
#endif
float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

/*
 ** Most likely this depends on your
 * screen rsolution.  Set the same 
 * values as the resolution of the
 * preview image of this editor.
*/
#define RESOLUTION vec2(500.0, 500.0)

// 0: rayleigh; 1: mie
#define OUTPUT 1

#define EARTH_RADIUS 637200.0
#define ATMOSPHERE_RADIUS 647200.0
#define RAYLEIGH_SCATTERING_COEFFICIENT vec3(0.000055, 0.00013, 0.000224)
#define MIE_SCATTERING_COEFFICIENT vec3(0.00004, 0.00004, 0.00004)
#define RAYLEIGH_SCALE_HEIGHT 8000.0
#define MIE_SCALE_HEIGHT 1200.0
#define MIE_DIRECTION 0.75

float getLuma(const vec3 col) {
    return dot(col, vec3(0.22, 0.707, 0.071));
}

vec3 tonemapReinhard(const vec3 col) {
    return clamp(1.0 - exp(-1.0 * col), 0.0, 1.0);
}

vec2 getRaySphereIntersection(const vec3 rayDir, const vec3 rayOrig, const float raySphere) {
    float a = dot(rayDir, rayDir);
    float b = 2.0 * dot(rayDir, rayOrig);
    float c = dot(rayOrig, rayOrig) - (raySphere * raySphere);
    float d = (b * b) - 4.0 * a * c;
    if (d < 0.0) {
        return vec2(10000.0, -10000.0);
    } else {
        return vec2((-b - sqrt(d)) / (2.0 * a), (-b + sqrt(d)) / (2.0 * a));
    }
}

vec3 getAtmosphere(const vec3 pos, const vec3 sunPos, const vec2 screenPos, const float frameTime, const float rainLevel, const float intensity) {
    const int numSteps = 128;

    vec3 totalSky = vec3(0.0, 0.0, 0.0);

    vec3 rayOrig = vec3(0.0, EARTH_RADIUS, 0.0);

    vec2 p = getRaySphereIntersection(pos, rayOrig, ATMOSPHERE_RADIUS);
    p.y = min(p.y, getRaySphereIntersection(pos, rayOrig, EARTH_RADIUS).x);

    float rayStepsize = (p.y - p.x) / float(numSteps);
    float raySteps = 0.0;

    vec3 totalRayleigh = vec3(0.0, 0.0, 0.0);
    vec3 totalMie = vec3(0.0, 0.0, 0.0);

    float rayLeighOpticalDepth = 0.0;
    float mieOpticalDepth = 0.0;
    
    float rayleighPhase = 3.0 / (16.0 * 3.14159265359) * (1.0 + dot(pos, sunPos) * dot(pos, sunPos));
    float miePhase = 3.0 / (8.0 * 3.14159265359) * ((1.0 - MIE_DIRECTION * MIE_DIRECTION) * (dot(pos, sunPos) * dot(pos, sunPos) + 1.0)) / (pow(1.0 + MIE_DIRECTION * MIE_DIRECTION - 2.0 * dot(pos, sunPos) * MIE_DIRECTION, 1.5) * (2.0 + MIE_DIRECTION * MIE_DIRECTION));

    for (int i = 0; i < numSteps; i++) {
        vec3 rayPos = rayOrig + pos * (raySteps + rayStepsize * 0.5);
        float rayHeight = length(rayPos) - EARTH_RADIUS;

        rayLeighOpticalDepth += exp(-rayHeight / RAYLEIGH_SCALE_HEIGHT) * rayStepsize;
        mieOpticalDepth += exp(-rayHeight / MIE_SCALE_HEIGHT) * rayStepsize;

        totalRayleigh += exp(-rayHeight / RAYLEIGH_SCALE_HEIGHT) * rayStepsize * exp(-(MIE_SCATTERING_COEFFICIENT * mieOpticalDepth + RAYLEIGH_SCATTERING_COEFFICIENT * rayLeighOpticalDepth));
        totalMie += exp(-rayHeight / MIE_SCALE_HEIGHT) * rayStepsize * exp(-(MIE_SCATTERING_COEFFICIENT * mieOpticalDepth + RAYLEIGH_SCATTERING_COEFFICIENT * rayLeighOpticalDepth));

        raySteps += rayStepsize;
    }
    
    vec3 rayleigh = RAYLEIGH_SCATTERING_COEFFICIENT * totalRayleigh;
    vec3 mie =  MIE_SCATTERING_COEFFICIENT * totalMie;
    
#	if OUTPUT == 0
    	totalSky = intensity * rayleigh;
#	elif OUTPUT == 1
    	totalSky = 10.0 * intensity * mie;
#	endif
    
    return tonemapReinhard(totalSky);
}

void main() {
    vec3 col = vec3(0.0, 0.0, 0.0);
    if (gl_FragCoord.x >= RESOLUTION.x || gl_FragCoord.y > RESOLUTION.y) return;
    
    vec2 uv = vec2(0.0, 0.0);
    uv.x = clamp(gl_FragCoord.x, 0.0, RESOLUTION.x) / RESOLUTION.x;
    uv.y = clamp(gl_FragCoord.y, 0.0, RESOLUTION.y) / RESOLUTION.y;
    
    vec3 sun = normalize(vec3(0.0, 2.0 * uv.x - 1.0, -sin(acos(clamp(2.0 * uv.x - 1.0, -1.0, 1.0)))));
    vec3 pos = normalize(vec3(0.0, 2.0 * uv.y - 1.0, -sin(acos(clamp(2.0 * uv.y - 1.0, -1.0, 1.0)))));
    
    col = getAtmosphere(pos, sun, vec2(0.0), 0.0, 0.0, mix(0.1, 1.0, max(sin(sun.y), 0.0)));

    gl_FragColor = vec4(col, 1.0);
}