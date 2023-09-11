#if !defined COMPOSITE2_GLSL_INCLUDED
#define COMPOSITE2_GLSL_INCLUDED

#if defined COMPOSITE2_FSH
#	extension GL_ARB_explicit_attrib_location : enable
	const bool colortex0MipmapEnabled = true;
	const bool colortex4MipmapEnabled = true;

	uniform sampler2D colortex0, colortex1, colortex2, colortex3, colortex4, colortex5, colortex6, colortex7, colortex8;
	uniform sampler2D depthtex0, depthtex1;
	uniform sampler2D shadowtex0, shadowtex1;
	uniform sampler2D shadowcolor0;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection, shadowModelView;
	uniform vec3 cameraPosition;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float far, near;
	uniform float fogStart, fogEnd;
	uniform int isEyeInWater;
	uniform int fogMode;

	in vec2 uv;
	in vec3 vNormal;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

	/* DRAWBUFFERS:038 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;

	float bayerX2(vec2 a) {
		return fract(dot(floor(a), vec2(0.5, floor(a).y * 0.75)));
	}

	#include "/utils/musk_rose_shadow.glsl"

	vec4 getShadowPos(const mat4 shadowModelView, const mat4 shadowProj, const vec3 relPos, const float diffuse) {
		const float shadowBias = 0.03;

		vec4 shadowPos = vec4(relPos, 1.0);
		shadowPos = shadowProj * (shadowModelView * shadowPos);

		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor);
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		
		shadowPos.z -= shadowBias * (distortFactor * distortFactor) / abs(diffuse);

		return shadowPos;
	}

	#define bayerX4(a)  (bayerX2 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX8(a)  (bayerX4 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX16(a) (bayerX8 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX32(a) (bayerX16(0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX64(a) (bayerX32(0.5 * (a)) * 0.25 + bayerX2(a))

	#include "/utils/musk_rose_config.glsl"

	vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
		vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

		return viewPos / viewPos.w;
	}

	vec3 getScreenPos(const mat4 proj, const vec3 pos) {
		vec4 viewPos = proj * vec4(pos, 1.0);

		return (viewPos.xyz / viewPos.w) * 0.5 + 0.5;
	}

	vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
		vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
		
		return relPos / relPos.w;
	}

	// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
	vec3 getEnvironmentBRDF(const vec3 H, const vec3 N, const float R, const vec3 reflectance) {
		vec4 r = R * vec4(-1.0, -0.0275, -0.572,  0.022) + vec4(1.0, 0.0425, 1.04, -0.04);
		vec2 AB = vec2(-1.04, 1.04) * min(r.x * r.x, exp2(-9.28 * max(0.0, dot(H, N)))) * r.x + r.y + r.zw;

		return reflectance * AB.x + AB.y;
	}

	vec3 contrastFilter(const vec3 col, const float contrast) {
		return (col - 0.5) * max(contrast, 0.0) + 0.5;
	}

	vec3 hdrExposure(const vec3 col, const float over, const float under) {
		return mix(col / over, col * under, col);
	}

	float getFog(const int fogMode, const float fogStart, const float fogEnd, const vec3 pos) {
		if (fogMode == 9729) { // GL_LINEAR
			return clamp((length(pos) - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
		} else if (fogMode == 2048) { // GL_EXP
			return 1.0 - clamp(1.0 / exp(max(0.0, length(pos) - fogStart) * log(1.0 / 0.03) / (fogEnd - fogStart)), 0.0, 1.0);
		} else if (fogMode == 2049) { // GL_EXP2
			float base = max(0.0, length(pos) - fogStart) * sqrt(log(1.0 / 0.015)) / (fogEnd - fogStart);
			return 1.0 - clamp(1.0 / exp(base * base), 0.0, 1.0);
		} else {
			return 0.0;
		}
	}

	#include "/utils/musk_rose_water.glsl" 
	#include "/utils/musk_rose_light.glsl"

	/* 
	** Uncharted 2 tonemapping
	** See: http://filmicworlds.com/blog/filmic-tonemapping-operators/
	*/
	vec3 uncharted2TonemapFilter(const vec3 col) {
		const float A = 0.015; // Shoulder strength
		const float B = 0.500; // Linear strength
		const float C = 0.100; // Linear angle
		const float D = 0.010; // Toe strength
		const float E = 0.020; // Toe numerator
		const float F = 0.300; // Toe denominator

		return ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
	}
	vec3 uncharted2Tonemap(const vec3 col, const float whiteLevel, const float exposure) {
		vec3 curr = uncharted2TonemapFilter(col * exposure);
		vec3 whiteScale = 1.0 / uncharted2TonemapFilter(vec3(whiteLevel, whiteLevel, whiteLevel));
		vec3 color = curr * whiteScale;

		return color;
	}

	void main() {
	float roughness = texture(colortex6, uv).r;
	float emissive = texture(colortex6, uv).g;
	float F0 = texture(colortex6, uv).b;
	float mcEntity = int(texture(colortex7, uv).r * 10.0 + 0.1);

	vec4 translucent = texture(colortex3, uv);
	vec3 albedo = texture(colortex0, uv).rgb;
	vec3 bloom = texture(colortex8, uv).rgb;
	vec3 fNormal = texture(colortex2, uv).rgb * 2.0 - 1.0;

	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;

	vec3 viewPos0 = getViewPos(gbufferProjectionInverse, uv, depth0).xyz;
	vec3 viewPos1 = getViewPos(gbufferProjectionInverse, uv, depth1).xyz;
	vec3 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0).xyz;
	vec3 fragPos = relPos + cameraPosition;

	vec4 totalFogRay = texture(colortex1, uv);

	vec3 pos = normalize(relPos);
	vec3 viewDir = -pos;
	vec3 reflectedLight = texture(colortex5, uv).rgb;

	bool isUnderwater = isEyeInWater == 0 ? int(mcEntity) == 1 : isEyeInWater == 1 ? int(mcEntity) != 1 : false;

	vec3 refraction = albedo;
	if (translucent.a > 0.0) {
		vec3 refNormal = mat3(gbufferModelView) * fNormal - normalize(cross(dFdx(viewPos0), dFdy(viewPos0)));
		vec2 refUV = getScreenPos(gbufferProjection, refract(normalize(viewPos0), refNormal, 0.0) + viewPos0).xy;
		refraction = textureLod(colortex0, refUV, 2.5 * translucent.a).rgb;
	}
	
	albedo = mix(refraction, translucent.rgb, translucent.a);

	if (depth0 != 1.0) {
		vec3 reflectance = mix(vec3(0.04, 0.04, 0.04), albedo, F0);
		vec3 specular = getPBRSpecular(viewDir, shadowLightPos, fNormal, roughness, reflectance);
		vec3 fresnel = fresnelSchlick(viewDir, fNormal, reflectance);

		vec3 reflectedImage = textureLod(colortex4, uv, 1.0 + roughness * 5.0).rgb;
		if (int(mcEntity) != 1) reflectedImage *= getEnvironmentBRDF(viewDir, fNormal, roughness, reflectance);

		albedo *= 1.0 - F0;
		albedo += reflectedImage * fresnel + min(10.0 * reflectedLight.rgb, specular);
		bloom += specular * reflectedLight;

		albedo /= albedo + 1.0;
		albedo = hdrExposure(albedo, 1.0, 2.2);
	}

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);

		/* colortex3 (composite) */
		fragData1 = translucent;

		/* colortex8 */
		fragData2 = vec4(bloom, texture(colortex8, uv).a);
	}
#endif /* defined COMPOSITE2_FSH */

#if defined COMPOSITE2_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 sunPosition, moonPosition, shadowLightPosition;

	in mat3 normalMatrix;
	in vec2 vaUV0;
	in vec3 vaPosition;
	in vec3 vaNormal;

	out vec2 uv;
	out vec3 vNormal;
	out vec3 sunPos;
	out vec3 moonPos;
	out vec3 shadowLightPos;

	void main() {
	uv = vaUV0;
	vNormal = normalize(normalMatrix * vaNormal);
	sunPos         = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	moonPos        = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE2_VSH */

#endif /* !defined COMPOSITE2_GLSL_INCLUDED */