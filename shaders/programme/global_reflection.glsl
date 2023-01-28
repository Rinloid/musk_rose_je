#if !defined REFLECTTION_INCLUCDED
#define REFLECTTION_INCLUCDED 1

#if defined REFLECTION_FRAGMENT
uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D colortex8;
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform float far, near;
uniform vec3 cameraPosition;
uniform int isEyeInWater;

varying vec2 uv;

#include "/utilities/muskRoseWater.glsl"
#include "/utilities/muskRoseHash.glsl"

vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
	vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

	return viewPos / viewPos.w;
}

vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
	vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
	
	return relPos / relPos.w;
}

// Based on one by Chocapic13
vec3 getRayTraceFactor(const sampler2D depthTex, const mat4 proj, const mat4 projInv, const vec3 viewPos, const vec3 reflectPos) {
	const int refinementSteps = 4;
	const int raySteps = 32;

	vec3 rayTracePosHit = vec3(0.0);
	
	vec3 refPos = reflectPos;
	vec3 startPos = viewPos + refPos + 0.05;
	vec3 tracePos = refPos + hash33(floor(viewPos * 2048.0)) * 0.1;

    int sr = 0;
    for (int i = 0; i < raySteps; i++) {
        vec4 uv = proj * vec4(startPos, 1.0);
        uv.xyz = uv.xyz / uv.w * 0.5 + 0.5;
       
	    if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1 || uv.z < 0 || uv.z > 1.0) {
			break;
		}

        vec3 viewPosAlt = getViewPos(projInv, uv.xy, texture2D(depthTex, uv.xy).x).xyz;
		if (distance(startPos, viewPosAlt) < length(refPos) * pow(length(tracePos), 0.1)) {
			sr++;
			if (sr >= refinementSteps) {
				rayTracePosHit = vec3(uv.xy, 1.0);
				break;
			}

			tracePos -= refPos;
			refPos *= 0.07;
        }

        refPos *= 2.0;
        tracePos += refPos;
		startPos = viewPos + tracePos;
	}

    return rayTracePosHit;
}

#define ENABLE_WATER_REFRACTION

void main() {
vec3 albedo = texture2D(gcolor, uv).rgb;
float depth = texture2D(depthtex0, uv).r;
vec3 viewPos = getViewPos(gbufferProjectionInverse, uv, depth).xyz;
vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth).xyz;
vec3 fragPos = relPos + cameraPosition;
vec3 normal = texture2D(gnormal, uv).rgb * 2.0 - 1.0;
float blendFlag = texture2D(gaux1, uv).b;
float waterFlag = texture2D(gaux3, uv).r;
float blendAlpha = texture2D(gaux3, uv).g;
vec3 blendCol = texture2D(gaux4, uv).rgb;
float cosTheta = 1.0 - abs(dot(normalize(relPos), normal));
vec3 reflected = vec3(0.0);
vec3 refracted = vec3(0.0);

if (blendFlag > 0.5) {
    vec3 refPos = reflect(normalize(viewPos), mat3(gbufferModelView) * normal);
    vec3 rayTracePosHit = getRayTraceFactor(depthtex0, gbufferProjection, gbufferProjectionInverse, viewPos, refPos);
    
    vec3 ssr = albedo;
    if (rayTracePosHit.z > 0.5 && isEyeInWater == 0) {
        ssr = texture2D(gcolor, rayTracePosHit.xy).rgb;
    } else {
        ssr = albedo;
    }

    reflected = ssr;
    refracted = texture2D(gaux2, uv.xy).rgb;
    #ifdef ENABLE_WATER_REFRACTION
        if (waterFlag > 0.5) {
            refracted = texture2D(gaux2, refract(vec3(uv, 1.0), getWaterWavNormal(getWaterParallax(viewPos, fragPos.xz, frameTimeCounter), frameTimeCounter) * 0.175, 1.0).xy).rgb;
        }
    #endif

    albedo = mix(refracted, reflected, max(blendAlpha, cosTheta));
    if (waterFlag < 0.5) {
        albedo = mix(blendCol, albedo, max(blendAlpha, cosTheta));
    }
}
    /* DRAWBUFFERS:0 */
    /*
     * 0 = gcolor
     * 1 = gdepth
     * 2 = gnormal
     * 3 = composite
     * 4 = gaux1
     * 5 = gaux2
     * 6 = gaux3
     * 7 = gaux4
    */
	gl_FragData[0] = vec4(albedo, 1.0); // gcolor
}

#endif /* defined REFLECTION_FRAGMENT */

#if defined REFLECTION_VERTEX
varying vec2 uv;

void main() {
uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	gl_Position = ftransform();
}
#endif /* defined REFLECTION_VERTEX */
#endif /* REFLECTTION_INCLUCDED */